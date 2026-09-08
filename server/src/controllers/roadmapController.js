import { sendSuccess, sendError } from "../utils/response.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import {
  roadmaps,
  findRoadmapByIdOrSlug,
  findTopicsByRoadmapId,
  enrollUserInRoadmap,
  getStudentRoadmapProgress,
  updateStudentTopicStatus,
} from "../db/inMemoryStore.js";

// Returns list of all available public roadmaps
export const getRoadmaps = async (req, res) => {
  try {
    if (isDatabaseConnected && supabase) {
      const { data, error } = await supabase
        .from("roadmaps")
        .select("*")
        .eq("is_public", true);

      if (!error && data && data.length > 0) {
        return sendSuccess(res, data, "Roadmaps retrieved successfully.");
      }
    }

    return sendSuccess(res, roadmaps, "Roadmaps retrieved successfully.");
  } catch (error) {
    return sendError(res, "Failed to retrieve roadmaps.", 500, error.message);
  }
};

// Returns roadmap details and its ordered topics with 3-tier Definition of Done
export const getRoadmapDetail = async (req, res) => {
  try {
    const { idOrSlug } = req.params;

    if (isDatabaseConnected && supabase) {
      const { data: allRoadmaps } = await supabase.from("roadmaps").select("*");
      const roadmap = allRoadmaps?.find(
        (r) => r.id === idOrSlug || r.slug === idOrSlug
      );

      if (roadmap) {
        const { data: topics } = await supabase
          .from("topics")
          .select("*")
          .eq("roadmap_id", roadmap.id)
          .order("order_index", { ascending: true });

        return sendSuccess(
          res,
          { ...roadmap, topics: topics || [] },
          "Roadmap details retrieved successfully."
        );
      }
    }

    const localRoadmap = findRoadmapByIdOrSlug(idOrSlug);
    if (!localRoadmap) {
      return sendError(res, `Roadmap '${idOrSlug}' not found.`, 404);
    }

    const localTopics = findTopicsByRoadmapId(localRoadmap.id);
    return sendSuccess(
      res,
      { ...localRoadmap, topics: localTopics },
      "Roadmap details retrieved successfully."
    );
  } catch (error) {
    return sendError(res, "Failed to retrieve roadmap details.", 500, error.message);
  }
};

// Enrolls authenticated user into a roadmap
export const enrollRoadmap = async (req, res) => {
  try {
    const { id } = req.params;

    if (isDatabaseConnected && supabase) {
      const { data: allRoadmaps } = await supabase.from("roadmaps").select("*");
      const roadmap = allRoadmaps?.find((r) => r.id === id || r.slug === id);

      if (roadmap) {
        const { data: existing } = await supabase
          .from("user_roadmaps")
          .select("*")
          .eq("user_id", req.user.id)
          .eq("roadmap_id", roadmap.id)
          .maybeSingle();

        if (existing) {
          return sendSuccess(res, existing, "User already enrolled in this roadmap.");
        }

        const { data: newEnrollment } = await supabase
          .from("user_roadmaps")
          .insert([
            {
              user_id: req.user.id,
              roadmap_id: roadmap.id,
              status: "in_progress",
              overall_progress_percent: 0,
            },
          ])
          .select()
          .single();

        if (newEnrollment) {
          const { data: topics } = await supabase
            .from("topics")
            .select("id, order_index")
            .eq("roadmap_id", roadmap.id)
            .order("order_index", { ascending: true });

          if (topics && topics.length > 0) {
            const topicRows = topics.map((t, index) => ({
              user_roadmap_id: newEnrollment.id,
              topic_id: t.id,
              status: index === 0 ? "in_progress" : "locked",
              attempts_count: 0,
            }));

            await supabase.from("user_topic_progress").insert(topicRows);
          }

          return sendSuccess(
            res,
            newEnrollment,
            "Successfully enrolled in roadmap. First topic unlocked!",
            201
          );
        }
      }
    }

    const localRoadmap = findRoadmapByIdOrSlug(id);
    if (!localRoadmap) {
      return sendError(res, `Roadmap '${id}' not found.`, 404);
    }

    const enrollment = enrollUserInRoadmap(req.user.id, localRoadmap.id);
    return sendSuccess(
      res,
      enrollment,
      "Successfully enrolled in roadmap. First topic unlocked!",
      201
    );
  } catch (error) {
    return sendError(res, "Enrollment failed.", 500, error.message);
  }
};

// Gets user progress across topics in a roadmap
export const getRoadmapProgress = async (req, res) => {
  try {
    const { id } = req.params;

    if (isDatabaseConnected && supabase) {
      const { data: allRoadmaps } = await supabase.from("roadmaps").select("*");
      const roadmap = allRoadmaps?.find((r) => r.id === id || r.slug === id);

      if (roadmap) {
        const { data: enrollment } = await supabase
          .from("user_roadmaps")
          .select("*")
          .eq("user_id", req.user.id)
          .eq("roadmap_id", roadmap.id)
          .maybeSingle();

        if (enrollment) {
          const { data: allTopics } = await supabase
            .from("topics")
            .select("*")
            .eq("roadmap_id", roadmap.id)
            .order("order_index", { ascending: true });

          const { data: progressRows } = await supabase
            .from("user_topic_progress")
            .select("*")
            .eq("user_roadmap_id", enrollment.id);

          const topicDetails = (allTopics || []).map((topic) => {
            const userProg = (progressRows || []).find((p) => p.topic_id === topic.id);
            return {
              ...topic,
              userProgress: userProg || { status: "locked", attempts_count: 0 },
            };
          });

          const completedRows = (progressRows || []).filter((p) => p.status === "completed");
          const completedCount = completedRows.length;

          let totalEstMinutes = 0;
          let completedEstMinutes = 0;
          (allTopics || []).forEach((t) => {
            const mins = parseInt(t.estimated_duration_min) || 45;
            totalEstMinutes += mins;
            const isDone = completedRows.some((p) => p.topic_id === t.id);
            if (isDone) completedEstMinutes += mins;
          });

          const startedAt = enrollment.started_at ? new Date(enrollment.started_at).getTime() : Date.now();
          const elapsedMinutes = Math.max(1, Math.round((Date.now() - startedAt) / (60 * 1000)));

          let velocityMultiplier = 1.0;
          if (completedCount > 0 && elapsedMinutes > 0) {
            velocityMultiplier = Number((completedEstMinutes / elapsedMinutes).toFixed(1));
            if (velocityMultiplier < 0.5) velocityMultiplier = 0.5;
            if (velocityMultiplier > 5.0) velocityMultiplier = 5.0;
          }

          const remainingMinutes = Math.max(0, totalEstMinutes - completedEstMinutes);
          const adjustedRemainingMinutes = Math.round(remainingMinutes / velocityMultiplier);
          const projectedCompletionDate = new Date(Date.now() + adjustedRemainingMinutes * 60 * 1000).toISOString();
          const isAccelerated = velocityMultiplier >= 1.3;
          const daysAhead = isAccelerated ? Math.max(1, Math.round((remainingMinutes - adjustedRemainingMinutes) / (60 * 24))) : 0;

          const velocityMetrics = {
            velocityMultiplier: `${velocityMultiplier}x`,
            learningPace: isAccelerated ? "Accelerated (Fast-Track)" : "Steady Pace",
            completedMinutes: completedEstMinutes,
            totalEstimatedMinutes: totalEstMinutes,
            projectedCompletionDate,
            daysAheadOfSchedule: daysAhead,
            summaryMessage: isAccelerated
              ? `You are learning ${velocityMultiplier}x faster than standard pace! Estimated completion: ${new Date(projectedCompletionDate).toLocaleDateString()}.`
              : "Steady progress. Master each Definition of Done to unlock the next milestone.",
          };

          return sendSuccess(
            res,
            {
              roadmap,
              enrollment,
              topics: topicDetails,
              velocityMetrics,
            },
            "Roadmap progress retrieved."
          );
        }
      }
    }

    const localRoadmap = findRoadmapByIdOrSlug(id);
    if (!localRoadmap) {
      return sendError(res, `Roadmap '${id}' not found.`, 404);
    }

    const progress = getStudentRoadmapProgress(req.user.id, localRoadmap.id);
    if (!progress) {
      return sendError(res, "User is not enrolled in this roadmap.", 404);
    }

    return sendSuccess(
      res,
      {
        ...progress,
        velocityMetrics: {
          velocityMultiplier: "1.0x",
          learningPace: "Steady Pace",
          projectedCompletionDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          daysAheadOfSchedule: 0,
          summaryMessage: "Steady progress. Pass assessments to unlock the next milestone.",
        },
      },
      "Roadmap progress retrieved."
    );
  } catch (error) {
    return sendError(res, "Failed to retrieve progress.", 500, error.message);
  }
};

// Updates student topic progress and unlocks the next topic if completed
export const updateTopicProgress = async (req, res) => {
  try {
    const { id, topicId } = req.params;
    const { status } = req.body;

    if (isDatabaseConnected && supabase) {
      const { data: allRoadmaps } = await supabase.from("roadmaps").select("*");
      const roadmap = allRoadmaps?.find((r) => r.id === id || r.slug === id);

      if (roadmap) {
        const { data: enrollment } = await supabase
          .from("user_roadmaps")
          .select("*")
          .eq("user_id", req.user.id)
          .eq("roadmap_id", roadmap.id)
          .maybeSingle();

        if (enrollment) {
          await supabase
            .from("user_topic_progress")
            .update({
              status,
              completed_at: status === "completed" ? new Date().toISOString() : null,
            })
            .eq("user_roadmap_id", enrollment.id)
            .eq("topic_id", topicId);

          let updatedEnrollment = enrollment;

          if (status === "completed") {
            const { data: allTopics } = await supabase
              .from("topics")
              .select("*")
              .eq("roadmap_id", roadmap.id)
              .order("order_index", { ascending: true });

            const { data: progressRows } = await supabase
              .from("user_topic_progress")
              .select("*")
              .eq("user_roadmap_id", enrollment.id);

            const completedCount = (progressRows || []).filter(
              (p) => p.status === "completed" || p.topic_id === topicId
            ).length;
            const totalCount = allTopics?.length || 1;
            const percent = Math.round((completedCount / totalCount) * 100);

            const { data: updated } = await supabase
              .from("user_roadmaps")
              .update({
                overall_progress_percent: percent,
                last_accessed_at: new Date().toISOString(),
                status: completedCount === totalCount ? "completed" : "in_progress",
              })
              .eq("id", enrollment.id)
              .select()
              .single();

            if (updated) {
              updatedEnrollment = updated;
            }

            const currentIdx = allTopics?.findIndex((t) => t.id === topicId) ?? -1;
            if (currentIdx !== -1 && currentIdx + 1 < allTopics.length) {
              const nextTopic = allTopics[currentIdx + 1];
              await supabase
                .from("user_topic_progress")
                .update({ status: "in_progress", started_at: new Date().toISOString() })
                .eq("user_roadmap_id", enrollment.id)
                .eq("topic_id", nextTopic.id);
            }
          }

          return sendSuccess(
            res,
            {
              userRoadmap: updatedEnrollment,
              updatedTopic: { status },
            },
            `Topic updated to '${status}'. Next topic progression evaluated.`
          );
        }
      }
    }

    const localRoadmap = findRoadmapByIdOrSlug(id);
    if (!localRoadmap) {
      return sendError(res, `Roadmap '${id}' not found.`, 404);
    }

    const result = updateStudentTopicStatus(req.user.id, localRoadmap.id, topicId, status);
    if (!result) {
      return sendError(res, "Unable to update topic progress. Check enrollment.", 400);
    }

    return sendSuccess(
      res,
      result,
      `Topic updated to '${status}'. Next topic progression evaluated.`
    );
  } catch (error) {
    return sendError(res, "Failed to update topic status.", 500, error.message);
  }
};
