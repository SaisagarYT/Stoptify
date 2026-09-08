import express from "express";
import { z } from "zod";
import {
  analyzeResumeEndpoint,
  startConsultationEndpoint,
  sendConsultationMessageEndpoint,
  finalizeConsultationEndpoint,
  getConsultationSessionEndpoint,
  calibrateFromInquiryEndpoint,
} from "../controllers/consultationController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";
import { rateLimiter } from "../middlewares/rateLimiter.js";
import { recordAuditLog } from "../middlewares/auditMiddleware.js";

import multer from "multer";
import { parseDocumentBuffer } from "../utils/documentParser.js";

const router = express.Router();

const consultationLimiter = rateLimiter({ windowMs: 60000, maxRequests: 40 });

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

const handleResumeUpload = async (req, res, next) => {
  try {
    if (req.file) {
      const extractedText = await parseDocumentBuffer(req.file);
      req.body.resumeText = extractedText;
    }
    next();
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: `Failed to extract text from document: ${err.message}`,
    });
  }
};

const resumeSchema = z.object({
  resumeText: z.string().min(20, { message: "Resume text must be at least 20 characters." }),
});

const startSchema = z.object({
  domain: z.string().min(2, { message: "Domain name is required." }),
});

const messageSchema = z.object({
  sessionId: z.string().uuid({ message: "Valid session ID is required." }),
  message: z.string().min(1, { message: "Message content cannot be empty." }),
});

const finalizeSchema = z.object({
  sessionId: z.string().uuid({ message: "Valid session ID is required." }),
});

router.post(
  "/analyze-resume",
  requireAuth,
  consultationLimiter,
  upload.single("resume"),
  handleResumeUpload,
  validate(resumeSchema),
  recordAuditLog("RESUME_ANALYZE"),
  analyzeResumeEndpoint
);

router.post(
  "/start",
  requireAuth,
  consultationLimiter,
  validate(startSchema),
  recordAuditLog("CONSULTATION_START"),
  startConsultationEndpoint
);

router.post(
  "/message",
  requireAuth,
  consultationLimiter,
  validate(messageSchema),
  sendConsultationMessageEndpoint
);

router.post(
  "/finalize",
  requireAuth,
  consultationLimiter,
  validate(finalizeSchema),
  recordAuditLog("ROADMAP_CUSTOM_GENERATE"),
  finalizeConsultationEndpoint
);

router.post(
  "/calibrate-from-inquiry",
  requireAuth,
  consultationLimiter,
  recordAuditLog("ROADMAP_CALIBRATE_INQUIRY"),
  calibrateFromInquiryEndpoint
);

router.get("/session/:sessionId", requireAuth, getConsultationSessionEndpoint);

export default router;


