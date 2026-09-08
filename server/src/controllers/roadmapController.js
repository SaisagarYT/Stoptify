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
          const { data: topicsProgress } = await supabase
            .from("user_topic_progress")
            .select("*, topic:topics(*)")
            .eq("user_roadmap_id", enrollment.id);

          return sendSuccess(
            res,
            {
              roadmap,
              enrollment,
              topicsProgress: topicsProgress || [],
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

    return sendSuccess(res, progress, "Roadmap progress retrieved.");
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

          if (status === "completed") {
            const { data: allTopics } = await supabase
              .from("topics")
              .select("*")
              .eq("roadmap_id", roadmap.id)
              .order("order_index", { ascending: true });

            const currentIdx = allTopics?.findIndex((t) => t.id === topicId) ?? -1;
            if (currentIdx !== -1 && currentIdx + 1 < allTopics.length) {
              const nextTopic = allTopics[currentIdx + 1];
              await supabase
                .from("user_topic_progress")
                .update({ status: "in_progress" })
                .eq("user_roadmap_id", enrollment.id)
                .eq("topic_id", nextTopic.id)
                .eq("status", "locked");
            }
          }

          return sendSuccess(
            res,
            { status },
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
