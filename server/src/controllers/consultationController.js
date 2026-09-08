import { randomUUID } from "node:crypto";
import { sendSuccess, sendError } from "../utils/response.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import {
  analyzeResumeContent,
  conductConsultationTurn,
  synthesizeCalibratedRoadmap,
} from "../services/aiService.js";
import {
  roadmaps,
  userSkills,
  enrollUserInRoadmap,
} from "../db/inMemoryStore.js";

// Active consultation sessions kept for conversational turns
const consultationSessions = new Map();

// Analyzes uploaded resume, extracts skills, and generates domain categories
export const analyzeResumeEndpoint = async (req, res) => {
  try {
    const { resumeText } = req.body;
    if (!resumeText || resumeText.trim().length === 0) {
      return sendError(res, "Resume text content is required.", 400);
    }

    const analysis = await analyzeResumeContent({ resumeText });

    // Store detected skills for the user
    if (analysis.detectedSkills && Array.isArray(analysis.detectedSkills)) {
      for (const skill of analysis.detectedSkills) {
        if (isDatabaseConnected && supabase) {
          await supabase.from("user_skills").upsert([
            {
              user_id: req.user.id,
              skill_name: skill.skillName,
              proficiency_level: Math.max(1, Math.min(5, skill.proficiencyLevel || 1)),
            },
          ]);
        } else {
          userSkills.push({
            id: randomUUID(),
            userId: req.user.id,
            skillName: skill.skillName,
            proficiencyLevel: Math.max(1, Math.min(5, skill.proficiencyLevel || 1)),
            assessedAt: new Date().toISOString(),
          });
        }
      }
    }

    return sendSuccess(
      res,
      analysis,
      "Resume analyzed successfully. Recommended domain categories generated."
    );
  } catch (error) {
    return sendError(res, "Failed to analyze resume.", 500, error.message);
  }
};

// Starts an interactive diagnostic consultation chat for a selected domain
export const startConsultationEndpoint = async (req, res) => {
  try {
    const { domain } = req.body;
    if (!domain) {
      return sendError(res, "Domain is required to start consultation.", 400);
    }

    // Retrieve user skills to inform initial greeting
    let skills = [];
    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("user_skills")
        .select("*")
        .eq("user_id", req.user.id);
      skills = data || [];
    } else {
      skills = userSkills.filter((s) => s.userId === req.user.id);
    }

    const sessionId = randomUUID();
    const initialGreeting = `Welcome! Let's tailor your journey in ${domain} so you eliminate tutorial hell and know exactly when to stop. First, what topics or concepts in ${domain} have you already completed or feel 100% confident in?`;

    const sessionData = {
      id: sessionId,
      userId: req.user.id,
      domain,
      userSkills: skills,
      conversationHistory: [
        { sender: "assistant", content: initialGreeting, timestamp: new Date().toISOString() },
      ],
      summary: {
        completedTopics: [],
        resourcePreference: "ai_generated",
        targetDepth: "mastery",
      },
      isReadyToFinalize: false,
      createdAt: new Date().toISOString(),
    };

    consultationSessions.set(sessionId, sessionData);

    return sendSuccess(
      res,
      {
        sessionId,
        domain,
        assistantReply: initialGreeting,
        history: sessionData.conversationHistory,
      },
      "Diagnostic consultation started."
    );
  } catch (error) {
    return sendError(res, "Failed to start consultation.", 500, error.message);
  }
};

// Handles a multi-turn message in the diagnostic consultation chat
export const sendConsultationMessageEndpoint = async (req, res) => {
  try {
    const { sessionId, message } = req.body;
    const session = consultationSessions.get(sessionId);

    if (!session || session.userId !== req.user.id) {
      return sendError(res, "Consultation session not found.", 404);
    }

    session.conversationHistory.push({
      sender: "user",
      content: message,
      timestamp: new Date().toISOString(),
    });

    const aiResult = await conductConsultationTurn({
      domain: session.domain,
      conversationHistory: session.conversationHistory,
      userSkills: session.userSkills,
      userMessage: message,
    });

    session.conversationHistory.push({
      sender: "assistant",
      content: aiResult.assistantReply,
      timestamp: new Date().toISOString(),
    });

    if (aiResult.completedTopicsIdentified && aiResult.completedTopicsIdentified.length > 0) {
      session.summary.completedTopics = Array.from(
        new Set([...session.summary.completedTopics, ...aiResult.completedTopicsIdentified])
      );
    }

    if (aiResult.resourcePreference) {
      session.summary.resourcePreference = aiResult.resourcePreference;
    }
    if (aiResult.targetDepth) {
      session.summary.targetDepth = aiResult.targetDepth;
    }

    session.isReadyToFinalize = Boolean(aiResult.isReadyToFinalize);

    return sendSuccess(
      res,
      {
        sessionId,
        assistantReply: aiResult.assistantReply,
        isReadyToFinalize: session.isReadyToFinalize,
        summary: session.summary,
      },
      "Consultation message processed."
    );
  } catch (error) {
    return sendError(res, "Failed to process consultation message.", 500, error.message);
  }
};

// Finalizes consultation and generates custom roadmap with explicit DoD & Anti-Scope
export const finalizeConsultationEndpoint = async (req, res) => {
  try {
    const { sessionId } = req.body;
    const session = consultationSessions.get(sessionId);

    if (!session || session.userId !== req.user.id) {
      return sendError(res, "Consultation session not found.", 404);
    }

    const roadmapJson = await synthesizeCalibratedRoadmap({
      domain: session.domain,
      consultationSummary: session.summary,
      userSkills: session.userSkills,
    });

    const uniqueSlug = `${roadmapJson.slug || "custom-roadmap"}-${Date.now().toString().slice(-5)}`;
    let createdRoadmap = null;
    let createdTopics = [];

    if (isDatabaseConnected && supabase) {
      const { data: rData, error: rErr } = await supabase
        .from("roadmaps")
        .insert([
          {
            title: roadmapJson.title,
            slug: uniqueSlug,
            target_career: roadmapJson.targetCareer || session.domain,
            duration_weeks: roadmapJson.durationWeeks || 4,
            difficulty_level: roadmapJson.difficultyLevel || "Intermediate",
            structure_template: { consultationSessionId: session.id },
            is_public: false,
            created_by: req.user.id,
          },
        ])
        .select()
        .single();

      if (rErr) {
        throw new Error(`Failed to save roadmap: ${rErr.message}`);
      }
      createdRoadmap = rData;

      if (roadmapJson.topics && Array.isArray(roadmapJson.topics)) {
        for (const t of roadmapJson.topics) {
          const { data: tData } = await supabase
            .from("topics")
            .insert([
              {
                roadmap_id: createdRoadmap.id,
                title: t.title,
                slug: `${t.slug || "topic"}-${t.orderIndex}`,
                description: t.description,
                order_index: t.orderIndex,
                estimated_duration_min: t.estimatedDurationMin || "45 min",
                definition_of_done: {
                  conceptual: t.definitionOfDone?.conceptual || "Explain core concept clearly",
                  practical: t.definitionOfDone?.practical || "Complete implementation exercise",
                  anti_scope: t.definitionOfDone?.anti_scope || "Do not explore edge features yet",
                  subtopics: t.subtopics || [],
                  real_world_example: t.realWorldExample || null,
                  when_to_stop: t.whenToStopCriteria || "Master core DoD to pass.",
                },
                anti_scope: t.antiScopeList || [],
                prerequisites_ids: [],
              },
            ])
            .select()
            .single();

          if (tData) {
            createdTopics.push(tData);
          }
        }
      }

      // Auto-enroll user in their newly generated custom roadmap
      const { data: userRoadmap } = await supabase
        .from("user_roadmaps")
        .insert([
          {
            user_id: req.user.id,
            roadmap_id: createdRoadmap.id,
            status: "in_progress",
            overall_progress_percent: 0.0,
          },
        ])
        .select()
        .single();

      // Sequential unlock: Unlock Topic 1, lock subsequent topics
      if (userRoadmap && createdTopics.length > 0) {
        for (let i = 0; i < createdTopics.length; i++) {
          await supabase.from("user_topic_progress").insert([
            {
              user_roadmap_id: userRoadmap.id,
              topic_id: createdTopics[i].id,
              status: i === 0 ? "in_progress" : "locked",
              attempts_count: 0,
            },
          ]);
        }
      }
    } else {
      createdRoadmap = {
        id: randomUUID(),
        title: roadmapJson.title,
        slug: uniqueSlug,
        targetCareer: roadmapJson.targetCareer || session.domain,
        durationWeeks: roadmapJson.durationWeeks || 4,
        difficultyLevel: roadmapJson.difficultyLevel || "Intermediate",
        isPublic: false,
        createdBy: req.user.id,
        createdAt: new Date().toISOString(),
      };
      roadmaps.push(createdRoadmap);

      enrollUserInRoadmap(req.user.id, createdRoadmap.id);
    }

    consultationSessions.delete(sessionId);

    return sendSuccess(
      res,
      {
        roadmap: createdRoadmap,
        topics: createdTopics,
        topicsCount: createdTopics.length,
      },
      "Custom calibrated roadmap synthesized and enrolled successfully.",
      201
    );
  } catch (error) {
    return sendError(res, "Failed to finalize consultation and create roadmap.", 500, error.message);
  }
};

// Returns current state of a consultation session
export const getConsultationSessionEndpoint = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const session = consultationSessions.get(sessionId);

    if (!session || session.userId !== req.user.id) {
      return sendError(res, "Consultation session not found.", 404);
    }

    return sendSuccess(res, session, "Consultation session retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve consultation session.", 500, error.message);
  }
};

// Calibrates custom roadmap directly from the 5-question resume diagnostic answers
export const calibrateFromInquiryEndpoint = async (req, res) => {
  try {
    const { resumeSummary, targetDomain = "Engineering", qaAnswers = [] } = req.body;

    // Retrieve user skills from database or in-memory
    let skills = [];
    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("user_skills")
        .select("*")
        .eq("user_id", req.user.id);
      skills = data || [];
    } else {
      skills = userSkills.filter((s) => s.userId === req.user.id);
    }

    const consultationSummary = {
      resumeSummary,
      completedTopics: [],
      targetDepth: "mastery",
      qaAnswers,
    };

    const roadmapJson = await synthesizeCalibratedRoadmap({
      domain: targetDomain,
      consultationSummary,
      userSkills: skills,
    });

    const uniqueSlug = `${roadmapJson.slug || "custom-roadmap"}-${Date.now().toString().slice(-5)}`;
    let createdRoadmap = null;
    let createdTopics = [];

    if (isDatabaseConnected && supabase) {
      const { data: rData, error: rErr } = await supabase
        .from("roadmaps")
        .insert([
          {
            title: roadmapJson.title,
            slug: uniqueSlug,
            target_career: roadmapJson.targetCareer || targetDomain,
            duration_weeks: roadmapJson.durationWeeks || 4,
            difficulty_level: roadmapJson.difficultyLevel || "Intermediate",
            structure_template: { qaAnswersCount: qaAnswers.length },
            is_public: false,
            created_by: req.user.id,
          },
        ])
        .select()
        .single();

      if (rErr) throw new Error(`Failed to save roadmap: ${rErr.message}`);
      createdRoadmap = rData;

      if (roadmapJson.topics && Array.isArray(roadmapJson.topics)) {
        for (const t of roadmapJson.topics) {
          const { data: tData } = await supabase
            .from("topics")
            .insert([
              {
                roadmap_id: createdRoadmap.id,
                title: t.title,
                slug: `${t.slug || "topic"}-${t.orderIndex}`,
                description: t.description,
                order_index: t.orderIndex,
                estimated_duration_min: t.estimatedDurationMin || "45 min",
                definition_of_done: {
                  conceptual: t.definitionOfDone?.conceptual || "Explain core concept clearly",
                  practical: t.definitionOfDone?.practical || "Complete implementation exercise",
                  anti_scope: t.definitionOfDone?.anti_scope || "Do not explore edge features yet",
                  subtopics: t.subtopics || [],
                  real_world_example: t.realWorldExample || null,
                  when_to_stop: t.whenToStopCriteria || "Master core DoD to pass.",
                },
                anti_scope: t.antiScopeList || [],
                prerequisites_ids: [],
              },
            ])
            .select()
            .single();

          if (tData) createdTopics.push(tData);
        }
      }

      // Auto-enroll user in the newly created roadmap
      const { data: userRoadmap } = await supabase
        .from("user_roadmaps")
        .insert([
          {
            user_id: req.user.id,
            roadmap_id: createdRoadmap.id,
            progress_percentage: 0.0,
          },
        ])
        .select()
        .single();

      if (userRoadmap && createdTopics.length > 0) {
        for (let i = 0; i < createdTopics.length; i++) {
          await supabase.from("user_topic_progress").insert([
            {
              user_roadmap_id: userRoadmap.id,
              topic_id: createdTopics[i].id,
              status: i === 0 ? "in_progress" : "locked",
              attempts_count: 0,
            },
          ]);
        }
      }
    } else {
      createdRoadmap = {
        id: randomUUID(),
        title: roadmapJson.title,
        slug: uniqueSlug,
        targetCareer: roadmapJson.targetCareer || targetDomain,
        durationWeeks: roadmapJson.durationWeeks || 4,
        difficultyLevel: roadmapJson.difficultyLevel || "Intermediate",
        isPublic: false,
        createdBy: req.user.id,
        createdAt: new Date().toISOString(),
      };
      roadmaps.push(createdRoadmap);
      enrollUserInRoadmap(req.user.id, createdRoadmap.id);
    }

    return sendSuccess(
      res,
      {
        roadmap: createdRoadmap,
        topics: createdTopics,
        topicsCount: createdTopics.length,
      },
      "Roadmap synthesized and enrolled from diagnostic inquiry.",
      201
    );
  } catch (error) {
    return sendError(res, "Failed to calibrate roadmap from inquiry.", 500, error.message);
  }
};

