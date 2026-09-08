import express from "express";
import { z } from "zod";
import {
  getTopicAssessments,
  submitMcq,
  submitSequenceOrdering,
  startOralExam,
  evaluateOralExam,
  generateAssessmentEndpoint,
} from "../controllers/assessmentController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";
import { rateLimiter } from "../middlewares/rateLimiter.js";
import { recordAuditLog } from "../middlewares/auditMiddleware.js";

const router = express.Router();

const examLimiter = rateLimiter({ windowMs: 60000, maxRequests: 30 });

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

const orderingSubmitSchema = z.object({
  answers: z.array(z.object({
    challengeId: z.string().optional(),
    challengeIndex: z.number().optional(),
    submittedSequence: z.array(z.string()),
  })),
});

router.get("/topic/:topicId", getTopicAssessments);
router.post("/generate/:topicId", requireAuth, examLimiter, recordAuditLog("AI_GENERATE_ASSESSMENT"), generateAssessmentEndpoint);
router.post("/oral/start", requireAuth, examLimiter, validate(oralStartSchema), recordAuditLog("ORAL_EXAM_START"), startOralExam);
router.post("/oral/evaluate", requireAuth, examLimiter, validate(oralEvaluateSchema), recordAuditLog("ORAL_EXAM_EVALUATE"), evaluateOralExam);
router.post("/:id/submit-mcq", requireAuth, examLimiter, validate(mcqSubmitSchema), recordAuditLog("MCQ_SUBMIT"), submitMcq);
router.post("/:id/submit-ordering", requireAuth, examLimiter, validate(orderingSubmitSchema), recordAuditLog("ORDERING_SUBMIT"), submitSequenceOrdering);

export default router;
