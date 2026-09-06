import { sampleRoadmap } from "../data/mockRoadmap.js";
import { sendSuccess, sendError } from "../utils/response.js";

// In-memory state for local testing before connecting Supabase database
let currentRoadmap = { ...sampleRoadmap };

/**
 * Controller: Get the full roadmap with all milestones
 */
// Returns the complete learning roadmap
export const getRoadmap = (req, res) => {
  try {
    return res.status(200).json({
      success: true,
      data: currentRoadmap,
    });
    return sendSuccess(res, currentRoadmap, "Roadmap fetched successfully");
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch roadmap",
      error: error.message,
    });
    return sendError(res, "Failed to fetch roadmap", 500, error.message);
  }
};

/**
 * Controller: Get a single milestone by its ID
 */
// Returns a single milestone by its ID
export const getMilestoneById = (req, res) => {
  try {
    const { id } = req.params;
    const milestone = currentRoadmap.milestones.find((m) => m.id === id);

    if (!milestone) {
      return res.status(404).json({
        success: false,
        message: `Milestone with ID '${id}' not found`,
      });
      return sendError(res, `Milestone with ID '${id}' not found`, 404);
    }

    return res.status(200).json({
      success: true,
      data: milestone,
    });
    return sendSuccess(res, milestone, "Milestone retrieved successfully");
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch milestone",
      error: error.message,
    });
    return sendError(res, "Failed to fetch milestone", 500, error.message);
  }
};

/**
 * Controller: Update milestone completion status (e.g. after passing oral exam or MCQ)
 */
// Marks a milestone completed and unlocks the next milestone
export const completeMilestone = (req, res) => {
  try {
    const { id } = req.params;
    const index = currentRoadmap.milestones.findIndex((m) => m.id === id);

    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: `Milestone with ID '${id}' not found`,
      });
      return sendError(res, `Milestone with ID '${id}' not found`, 404);
    }

    // Mark current node as completed
    currentRoadmap.milestones[index].status = "completed";

    // Unlock the next node if it exists
    // Unlock next milestone if available
    if (index + 1 < currentRoadmap.milestones.length) {
      if (currentRoadmap.milestones[index + 1].status === "locked") {
        currentRoadmap.milestones[index + 1].status = "in_progress";
      }
    }

    return res.status(200).json({
      success: true,
      message: `Milestone '${id}' marked as completed! Next milestone unlocked.`,
      data: currentRoadmap.milestones[index],
    });
    return sendSuccess(
      res,
      currentRoadmap.milestones[index],
      `Milestone '${id}' marked completed`
    );
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to complete milestone",
      error: error.message,
    });
    return sendError(res, "Failed to complete milestone", 500, error.message);
  }
};
