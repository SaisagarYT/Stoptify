import { sampleRoadmap } from "../data/mockRoadmap.js";

// In-memory state for local testing before connecting Supabase database
let currentRoadmap = { ...sampleRoadmap };

/**
 * Controller: Get the full roadmap with all milestones
 */
export const getRoadmap = (req, res) => {
  try {
    return res.status(200).json({
      success: true,
      data: currentRoadmap,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch roadmap",
      error: error.message,
    });
  }
};

/**
 * Controller: Get a single milestone by its ID
 */
export const getMilestoneById = (req, res) => {
  try {
    const { id } = req.params;
    const milestone = currentRoadmap.milestones.find((m) => m.id === id);

    if (!milestone) {
      return res.status(404).json({
        success: false,
        message: `Milestone with ID '${id}' not found`,
      });
    }

    return res.status(200).json({
      success: true,
      data: milestone,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch milestone",
      error: error.message,
    });
  }
};

/**
 * Controller: Update milestone completion status (e.g. after passing oral exam or MCQ)
 */
export const completeMilestone = (req, res) => {
  try {
    const { id } = req.params;
    const index = currentRoadmap.milestones.findIndex((m) => m.id === id);

    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: `Milestone with ID '${id}' not found`,
      });
    }

    // Mark current node as completed
    currentRoadmap.milestones[index].status = "completed";

    // Unlock the next node if it exists
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
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to complete milestone",
      error: error.message,
    });
  }
};
