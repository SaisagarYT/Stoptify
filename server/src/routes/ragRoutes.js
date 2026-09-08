import express from "express";
import { z } from "zod";
import {
  uploadDocument,
  getUploads,
  searchRag,
  getTopicContent,
  generateTopicChapterEndpoint,
} from "../controllers/ragController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";
import { rateLimiter } from "../middlewares/rateLimiter.js";
import { recordAuditLog } from "../middlewares/auditMiddleware.js";

const router = express.Router();

const ragLimiter = rateLimiter({ windowMs: 60000, maxRequests: 50 });

const uploadSchema = z.object({
  fileName: z.string().min(1, { message: "File name is required." }),
  content: z.string().min(1, { message: "Content cannot be empty." }),
  fileType: z.string().optional(),
});

const searchSchema = z.object({
  query: z.string().min(1, { message: "Query string is required." }),
  limit: z.number().int().min(1).max(20).optional(),
});

router.post("/upload", requireAuth, ragLimiter, validate(uploadSchema), recordAuditLog("DOCUMENT_UPLOAD"), uploadDocument);
router.get("/uploads", requireAuth, ragLimiter, getUploads);
router.post("/search", requireAuth, ragLimiter, validate(searchSchema), recordAuditLog("RAG_SEARCH"), searchRag);
router.post("/generate/:topicId", requireAuth, ragLimiter, recordAuditLog("AI_GENERATE_CONTENT"), generateTopicChapterEndpoint);
router.get("/content/:topicId", getTopicContent);

export default router;

