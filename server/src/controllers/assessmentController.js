import { sendSuccess, sendError } from "../utils/response.js";
import {
  getAssessmentsByTopicId,
  getAssessmentById,
  getUserTopicProgressRecord,
  recordAssessmentResult,
  recordOralExamSession,
  updateStudentTopicStatus,
} from "../db/inMemoryStore.js";

// Returns all assessments available for a specific topic
export const getTopicAssessments = (req, res) => {
  try {
    const { topicId } = req.params;
    const topicAssessments = getAssessmentsByTopicId(topicId);

    return sendSuccess(res, topicAssessments, "Topic assessments retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve assessments.", 500, error.message);
  }
};

// Submits and grades a multiple choice assessment
export const submitMcq = (req, res) => {
  try {
    const { id } = req.params;
    const { answers } = req.body;

    const assessment = getAssessmentById(id);
    if (!assessment || assessment.type !== "mcq") {
      return sendError(res, "MCQ assessment not found.", 404);
    }

    const progressRecord = getUserTopicProgressRecord(req.user.id, assessment.topic_id);
    if (!progressRecord) {
      return sendError(res, "User is not enrolled in this topic's roadmap.", 400);
    }

    const questions = assessment.questions;
    let correctCount = 0;
    const itemFeedback = [];

    questions.forEach((q, idx) => {
      const userAnswer = answers.find((a) => a.questionId === q.id || a.questionIndex === idx);
      const isCorrect = userAnswer && userAnswer.selectedIndex === q.correct_index;
      if (isCorrect) correctCount += 1;

      itemFeedback.push({
        questionId: q.id,
        isCorrect: Boolean(isCorrect),
        explanation: q.explanation,
      });
    });

    const score = Math.round((correctCount / questions.length) * 100);
    const passed = score >= assessment.passing_score_threshold;

    const resultRecord = recordAssessmentResult({
      userTopicProgressId: progressRecord.progress.id,
      assessmentId: assessment.id,
      score,
      feedback: { itemFeedback },
      userAnswersSnapshot: answers,
      passed,
    });

    if (passed) {
      updateStudentTopicStatus(
        req.user.id,
        progressRecord.topic.roadmap_id,
        progressRecord.topic.id,
        "completed"
      );
    }

    return sendSuccess(res, {
      score,
      passed,
      passingThreshold: assessment.passing_score_threshold,
      resultId: resultRecord.id,
      itemFeedback,
      remediationNeeded: !passed,
    }, passed ? "Assessment passed! Next milestone unlocked." : "Assessment not passed. Review feedback.");
  } catch (error) {
    return sendError(res, "Failed to evaluate assessment.", 500, error.message);
  }
};

// Initiates a 3-probe Feynman oral defense session
export const startOralExam = (req, res) => {
  try {
    const { topicId } = req.body;
    const oralAssessments = getAssessmentsByTopicId(topicId).filter((a) => a.type === "oral_exam");

    if (oralAssessments.length === 0) {
      return sendError(res, "Oral assessment not configured for this topic.", 404);
    }

    const assessment = oralAssessments[0];

    return sendSuccess(res, {
      assessmentId: assessment.id,
      topicId: assessment.topic_id,
      timeLimitSeconds: assessment.time_limit_seconds,
      probes: assessment.questions,
    }, "Feynman oral examination initiated.");
  } catch (error) {
    return sendError(res, "Failed to start oral exam.", 500, error.message);
  }
};

// Evaluates oral responses against Definition of Done rubric
export const evaluateOralExam = (req, res) => {
  try {
    const { assessmentId, transcript = "", responses = [] } = req.body;

    const assessment = getAssessmentById(assessmentId);
    if (!assessment || assessment.type !== "oral_exam") {
      return sendError(res, "Oral assessment not found.", 404);
    }

    const progressRecord = getUserTopicProgressRecord(req.user.id, assessment.topic_id);
    if (!progressRecord) {
      return sendError(res, "User is not enrolled in this topic's roadmap.", 400);
    }

    const rubric = assessment.grading_rubric || {};
    let scorePoints = 0;
    const probeEvaluations = [];

    const fullText = (transcript + " " + responses.map((r) => r.answer || "").join(" ")).toLowerCase();

    const eli5Matches = (rubric.eli5_keywords || []).filter((kw) => fullText.includes(kw.toLowerCase()));
    const eli5Score = eli5Matches.length > 0 ? 35 : 15;
    scorePoints += eli5Score;
    probeEvaluations.push({
      tier: "eli5_core",
      score: eli5Score,
      passed: eli5Score >= 30,
      feedback: eli5Score >= 30
        ? "Clear distillation of the core concept in plain language."
        : "Core concept needs clearer non-jargon explanation.",
    });

    const tradeoffMatches = (rubric.tradeoff_keywords || []).filter((kw) => fullText.includes(kw.toLowerCase()));
    const tradeoffScore = tradeoffMatches.length > 0 ? 35 : 15;
    scorePoints += tradeoffScore;
    probeEvaluations.push({
      tier: "tradeoff_edge_case",
      score: tradeoffScore,
      passed: tradeoffScore >= 30,
      feedback: tradeoffScore >= 30
        ? "Good articulation of limitations and architectural trade-offs."
        : "Missed key trade-offs and edge case constraints.",
    });

    const appMatches = (rubric.application_keywords || []).filter((kw) => fullText.includes(kw.toLowerCase()));
    const appScore = appMatches.length > 0 ? 30 : 10;
    scorePoints += appScore;
    probeEvaluations.push({
      tier: "real_world_application",
      score: appScore,
      passed: appScore >= 25,
      feedback: appScore >= 25
        ? "Strong practical troubleshooting approach demonstrated."
        : "Review production troubleshooting strategies for this topic.",
    });

    const totalScore = Math.min(100, scorePoints);
    const passed = totalScore >= assessment.passing_score_threshold;

    const resultRecord = recordAssessmentResult({
      userTopicProgressId: progressRecord.progress.id,
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

    if (passed) {
      updateStudentTopicStatus(
        req.user.id,
        progressRecord.topic.roadmap_id,
        progressRecord.topic.id,
        "completed"
      );
    }

    return sendSuccess(res, {
      score: totalScore,
      passed,
      passingThreshold: assessment.passing_score_threshold,
      resultId: resultRecord.id,
      sessionId: sessionRecord.id,
      probeEvaluations,
      remediationSnippet: passed ? null : "Focus on B-tree write overhead and idempotent request design.",
    }, passed ? "Feynman Oral Defense passed! Mastery verified." : "Oral Defense incomplete. Review remediation guidance.");
  } catch (error) {
    return sendError(res, "Failed to evaluate oral defense.", 500, error.message);
  }
};
