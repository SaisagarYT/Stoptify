import { Router } from "express";
import { getAuditHistory } from "../controllers/auditController.js";
import { requireAuth } from "../middlewares/authMiddleware.js";

const router = Router();

// Retrieve audit logs for current user
router.get("/audit-logs", requireAuth, getAuditHistory);

export default router;

