import { sendSuccess, sendError } from "../utils/response.js";
import {
  roadmaps,
  findRoadmapByIdOrSlug,
  findTopicsByRoadmapId,
  enrollUserInRoadmap,
  getStudentRoadmapProgress,
  updateStudentTopicStatus,
} from "../db/inMemoryStore.js";

// Returns list of all available public roadmaps
export const getRoadmaps = (req, res) => {
  try {
    return sendSuccess(res, roadmaps, "Roadmaps retrieved successfully.");
  } catch (error) {
    return sendError(res, "Failed to retrieve roadmaps.", 500, error.message);
  }
};

// Returns roadmap details and its ordered topics with 3-tier Definition of Done
export const getRoadmapDetail = (req, res) => {
  try {
    const { idOrSlug } = req.params;
    const roadmap = findRoadmapByIdOrSlug(idOrSlug);

    if (!roadmap) {
      return sendError(res, `Roadmap '${idOrSlug}' not found.`, 404);
    }

    const roadmapTopics = findTopicsByRoadmapId(roadmap.id);

    return sendSuccess(
      res,
      { ...roadmap, topics: roadmapTopics },
      "Roadmap details retrieved successfully."
    );
  } catch (error) {
    return sendError(res, "Failed to retrieve roadmap details.", 500, error.message);
  }
};

// Enrolls authenticated user into a roadmap
export const enrollRoadmap = (req, res) => {
  try {
    const { id } = req.params;
    const roadmap = findRoadmapByIdOrSlug(id);

    if (!roadmap) {
      return sendError(res, `Roadmap '${id}' not found.`, 404);
    }

    const enrollment = enrollUserInRoadmap(req.user.id, roadmap.id);

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
export const getRoadmapProgress = (req, res) => {
  try {
    const { id } = req.params;
    const roadmap = findRoadmapByIdOrSlug(id);

    if (!roadmap) {
      return sendError(res, `Roadmap '${id}' not found.`, 404);
    }

    const progress = getStudentRoadmapProgress(req.user.id, roadmap.id);

    if (!progress) {
      return sendError(res, "User is not enrolled in this roadmap.", 404);
    }

    return sendSuccess(res, progress, "Roadmap progress retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve progress.", 500, error.message);
  }
};

// Updates student topic progress and unlocks the next topic if completed
export const updateTopicProgress = (req, res) => {
  try {
    const { id, topicId } = req.params;
    const { status } = req.body;

    const roadmap = findRoadmapByIdOrSlug(id);
    if (!roadmap) {
      return sendError(res, `Roadmap '${id}' not found.`, 404);
    }

    const result = updateStudentTopicStatus(req.user.id, roadmap.id, topicId, status);

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
