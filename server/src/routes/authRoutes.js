import express from "express";
import { z } from "zod";
import { register, login, getMe } from "../controllers/authController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";
import { rateLimiter } from "../middlewares/rateLimiter.js";
import { recordAuditLog } from "../middlewares/auditMiddleware.js";

const router = express.Router();

const authLimiter = rateLimiter({ windowMs: 60000, maxRequests: 20 });

const registerSchema = z.object({
  email: z.string().email({ message: "Must be a valid email address." }),
  password: z.string().min(6, { message: "Password must be at least 6 characters." }),
  fullName: z.string().min(2, { message: "Full name must be at least 2 characters." }),
});

const loginSchema = z.object({
  email: z.string().email({ message: "Must be a valid email address." }),
  password: z.string().min(1, { message: "Password is required." }),
});

router.post("/register", authLimiter, validate(registerSchema), recordAuditLog("USER_REGISTER"), register);
router.post("/login", authLimiter, validate(loginSchema), recordAuditLog("USER_LOGIN"), login);
router.get("/me", requireAuth, getMe);

export default router;
