import express from "express";
import { z } from "zod";
import {
  getRoadmaps,
  getRoadmapDetail,
  enrollRoadmap,
  getRoadmapProgress,
  updateTopicProgress,
} from "../controllers/roadmapController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";

const router = express.Router();

// Schema for updating topic status
const topicStatusSchema = z.object({
  status: z.enum(["locked", "in_progress", "completed"], {
    message: "Status must be 'locked', 'in_progress', or 'completed'.",
  }),
});

// Public endpoints
router.get("/", getRoadmaps);
router.get("/:idOrSlug", getRoadmapDetail);

// Protected learner progression endpoints
router.post("/:id/enroll", requireAuth, enrollRoadmap);
router.get("/:id/progress", requireAuth, getRoadmapProgress);
router.patch("/:id/topics/:topicId", requireAuth, validate(topicStatusSchema), updateTopicProgress);

export default router;
