import express from "express";
import { z } from "zod";
import {
  uploadDocument,
  getUploads,
  searchRag,
  getTopicContent,
} from "../controllers/ragController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";

const router = express.Router();

const uploadSchema = z.object({
  fileName: z.string().min(1, { message: "File name is required." }),
  content: z.string().min(1, { message: "Content cannot be empty." }),
  fileType: z.string().optional(),
});

const searchSchema = z.object({
  query: z.string().min(1, { message: "Query string is required." }),
  limit: z.number().int().min(1).max(20).optional(),
});

router.post("/upload", requireAuth, validate(uploadSchema), uploadDocument);
router.get("/uploads", requireAuth, getUploads);
router.post("/search", requireAuth, validate(searchSchema), searchRag);
router.get("/content/:topicId", getTopicContent);

export default router;
