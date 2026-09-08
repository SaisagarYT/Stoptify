import { sendSuccess, sendError } from "../utils/response.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import {
  getAssessmentsByTopicId,
  getAssessmentById,
  getUserTopicProgressRecord,
  recordAssessmentResult,
  recordOralExamSession,
  updateStudentTopicStatus,
} from "../db/inMemoryStore.js";

// Returns all assessments available for a specific topic
export const getTopicAssessments = async (req, res) => {
  try {
    const { topicId } = req.params;

    if (isDatabaseConnected && supabase) {
      const { data, error } = await supabase
        .from("assessments")
        .select("*")
        .eq("topic_id", topicId)
        .eq("is_active", true);

      if (!error && data && data.length > 0) {
        return sendSuccess(res, data, "Topic assessments retrieved.");
      }
    }

    const topicAssessments = getAssessmentsByTopicId(topicId);
    return sendSuccess(res, topicAssessments, "Topic assessments retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve assessments.", 500, error.message);
  }
};

// Submits and grades a multiple choice assessment
export const submitMcq = async (req, res) => {
  try {
    const { id } = req.params;
    const { answers } = req.body;

    let assessment = null;
    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("assessments")
        .select("*")
        .eq("id", id)
        .maybeSingle();
      assessment = data;
    }

    if (!assessment) {
      assessment = getAssessmentById(id);
    }

    if (!assessment || assessment.type !== "mcq") {
      return sendError(res, "MCQ assessment not found.", 404);
    }

    const questions = assessment.questions || [];
    let correctCount = 0;
    const itemFeedback = [];

    questions.forEach((q, idx) => {
      const userAnswer = answers.find(
        (a) => a.questionId === q.id || a.questionIndex === idx
      );
      const isCorrect = userAnswer && userAnswer.selectedIndex === q.correct_index;
      if (isCorrect) correctCount += 1;

      itemFeedback.push({
        questionId: q.id,
        isCorrect: Boolean(isCorrect),
        explanation: q.explanation,
      });
    });

    const score = questions.length > 0 ? Math.round((correctCount / questions.length) * 100) : 0;
    const passed = score >= assessment.passing_score_threshold;

    const progressRecord = getUserTopicProgressRecord(req.user.id, assessment.topic_id);
    const userTopicProgressId = progressRecord?.progress?.id || req.user.id;

    const resultRecord = recordAssessmentResult({
      userTopicProgressId,
      assessmentId: assessment.id,
      score,
      feedback: { itemFeedback },
      userAnswersSnapshot: answers,
      passed,
    });

    if (isDatabaseConnected && supabase) {
      try {
        await supabase.from("user_assessment_results").insert([
          {
            user_topic_progress_id: userTopicProgressId,
            assessment_id: assessment.id,
            score,
            feedback: { itemFeedback },
            user_answers_snapshot: answers,
            passed,
          },
        ]);
      } catch (dbErr) {
        // Fallback to in-memory result if foreign key is not present
      }
    }

    if (passed && progressRecord?.topic) {
      updateStudentTopicStatus(
        req.user.id,
        progressRecord.topic.roadmap_id,
        progressRecord.topic.id,
        "completed"
      );
    }

    return sendSuccess(
      res,
      {
        score,
        passed,
        passingThreshold: assessment.passing_score_threshold,
        resultId: resultRecord.id,
        itemFeedback,
        remediationNeeded: !passed,
      },
      passed
        ? "Assessment passed! Next milestone unlocked."
        : "Assessment not passed. Review feedback."
    );
  } catch (error) {
    return sendError(res, "Failed to evaluate assessment.", 500, error.message);
  }
};

// Initiates a 3-probe Feynman oral defense session
export const startOralExam = async (req, res) => {
  try {
    const { topicId } = req.body;
    let assessment = null;

    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("assessments")
        .select("*")
        .eq("topic_id", topicId)
        .eq("type", "oral_exam")
        .eq("is_active", true)
        .maybeSingle();

      assessment = data;
    }

    if (!assessment) {
      const oralAssessments = getAssessmentsByTopicId(topicId).filter(
        (a) => a.type === "oral_exam"
      );
      if (oralAssessments.length > 0) {
        assessment = oralAssessments[0];
      }
    }

    if (!assessment) {
      return sendError(res, "Oral assessment not configured for this topic.", 404);
    }

    return sendSuccess(
      res,
      {
        assessmentId: assessment.id,
        topicId: assessment.topic_id,
        timeLimitSeconds: assessment.time_limit_seconds,
        probes: assessment.questions,
      },
      "Feynman oral examination initiated."
    );
  } catch (error) {
    return sendError(res, "Failed to start oral exam.", 500, error.message);
  }
};

// Evaluates oral responses against Definition of Done rubric
export const evaluateOralExam = async (req, res) => {
  try {
    const { assessmentId, transcript = "", responses = [] } = req.body;

    let assessment = null;
    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("assessments")
        .select("*")
        .eq("id", assessmentId)
        .maybeSingle();
      assessment = data;
    }

    if (!assessment) {
      assessment = getAssessmentById(assessmentId);
    }

    if (!assessment || assessment.type !== "oral_exam") {
      return sendError(res, "Oral assessment not found.", 404);
    }

    const rubric = assessment.grading_rubric || {};
    let scorePoints = 0;
    const probeEvaluations = [];

    const fullText = (
      transcript + " " + responses.map((r) => r.answer || "").join(" ")
    ).toLowerCase();

    // Probe 1: Conceptual clarity
    const eli5Matches = (rubric.eli5_keywords || ["state", "same", "repeat"]).filter((kw) =>
      fullText.includes(kw.toLowerCase())
    );
    const eli5Score = eli5Matches.length > 0 ? 35 : 15;
    scorePoints += eli5Score;
    probeEvaluations.push({
      tier: "eli5_core",
      score: eli5Score,
      passed: eli5Score >= 30,
      feedback:
        eli5Score >= 30
          ? "Clear distillation of the core concept in plain language."
          : "Core concept needs clearer non-jargon explanation.",
    });

    // Probe 2: Trade-off and edge case
    const tradeoffMatches = (rubric.tradeoff_keywords || ["uri", "identifier", "resource"]).filter((kw) =>
      fullText.includes(kw.toLowerCase())
    );
    const tradeoffScore = tradeoffMatches.length > 0 ? 35 : 15;
    scorePoints += tradeoffScore;
    probeEvaluations.push({
      tier: "tradeoff_edge_case",
      score: tradeoffScore,
      passed: tradeoffScore >= 30,
      feedback:
        tradeoffScore >= 30
          ? "Good articulation of limitations and architectural trade-offs."
          : "Missed key trade-offs and edge case constraints.",
    });

    // Probe 3: Real world application
    const appMatches = (rubric.application_keywords || ["token", "key", "constraint"]).filter((kw) =>
      fullText.includes(kw.toLowerCase())
    );
    const appScore = appMatches.length > 0 ? 30 : 10;
    scorePoints += appScore;
    probeEvaluations.push({
      tier: "real_world_application",
      score: appScore,
      passed: appScore >= 25,
      feedback:
        appScore >= 25
          ? "Strong practical troubleshooting approach demonstrated."
          : "Review production troubleshooting strategies for this topic.",
    });

    const totalScore = Math.min(100, scorePoints);
    const passed = totalScore >= assessment.passing_score_threshold;

    const progressRecord = getUserTopicProgressRecord(req.user.id, assessment.topic_id);
    const userTopicProgressId = progressRecord?.progress?.id || req.user.id;

    const resultRecord = recordAssessmentResult({
      userTopicProgressId,
      assessmentId: assessment.id,
      score: totalScore,
      feedback: { probeEvaluations },
      userAnswersSnapshot: { transcript, responses },
      passed,
    });

    const sessionRecord = recordOralExamSession({
      userAssessmentResultId: resultRecord.id,
      transcript,
      aiEvaluation: { probeEvaluations, score: totalScore },
      confidenceScore: passed ? 0.92 : 0.65,
      sessionStatus: "completed",
    });

    if (isDatabaseConnected && supabase) {
      try {
        await supabase.from("user_assessment_results").insert([
          {
            user_topic_progress_id: userTopicProgressId,
            assessment_id: assessment.id,
            score: totalScore,
            feedback: { probeEvaluations },
            user_answers_snapshot: { transcript, responses },
            passed,
          },
        ]);
      } catch (dbErr) {
        // Fallback to local
      }
    }

    if (passed && progressRecord?.topic) {
      updateStudentTopicStatus(
        req.user.id,
        progressRecord.topic.roadmap_id,
        progressRecord.topic.id,
        "completed"
      );
    }

    return sendSuccess(
      res,
      {
        score: totalScore,
        passed,
        passingThreshold: assessment.passing_score_threshold,
        resultId: resultRecord.id,
        sessionId: sessionRecord.id,
        probeEvaluations,
        remediationSnippet: passed
          ? null
          : "Focus on B-tree write overhead and idempotent request design.",
      },
      passed
        ? "Feynman Oral Defense passed! Mastery verified."
        : "Oral Defense incomplete. Review remediation guidance."
    );
  } catch (error) {
    return sendError(res, "Failed to evaluate oral defense.", 500, error.message);
  }
};
