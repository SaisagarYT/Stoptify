import express from "express";
import { z } from "zod";
import {
  getTopicAssessments,
  submitMcq,
  startOralExam,
  evaluateOralExam,
} from "../controllers/assessmentController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";

const router = express.Router();

const oralStartSchema = z.object({
  topicId: z.string().min(1, { message: "Topic ID is required." }),
});

const oralEvaluateSchema = z.object({
  assessmentId: z.string().min(1, { message: "Assessment ID is required." }),
  transcript: z.string().optional(),
  responses: z.array(z.object({
    tier: z.string().optional(),
    answer: z.string().optional(),
  })).optional(),
});

const mcqSubmitSchema = z.object({
  answers: z.array(z.object({
    questionId: z.string().optional(),
    questionIndex: z.number().optional(),
    selectedIndex: z.number(),
  })),
});

router.get("/topic/:topicId", getTopicAssessments);
router.post("/oral/start", requireAuth, validate(oralStartSchema), startOralExam);
router.post("/oral/evaluate", requireAuth, validate(oralEvaluateSchema), evaluateOralExam);
router.post("/:id/submit-mcq", requireAuth, validate(mcqSubmitSchema), submitMcq);

export default router;
