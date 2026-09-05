import express from "express";
import {
  getRoadmap,
  getMilestoneById,
  completeMilestone,
} from "../controllers/roadmapController.js";

const router = express.Router();

// GET /api/roadmap - Fetch full roadmap
router.get("/", getRoadmap);

// GET /api/roadmap/:id - Fetch single milestone
router.get("/:id", getMilestoneById);

// POST /api/roadmap/:id/complete - Mark a milestone completed & unlock next
router.post("/:id/complete", completeMilestone);

export default router;
