import express from "express";
import { z } from "zod";
import { register, login, getMe } from "../controllers/authController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";

const router = express.Router();

// Simple validation schemas
const registerSchema = z.object({
  email: z.string().email({ message: "Must be a valid email address." }),
  password: z.string().min(6, { message: "Password must be at least 6 characters." }),
  fullName: z.string().min(2, { message: "Full name must be at least 2 characters." }),
});

const loginSchema = z.object({
  email: z.string().email({ message: "Must be a valid email address." }),
  password: z.string().min(1, { message: "Password is required." }),
});

// Auth endpoints
router.post("/register", validate(registerSchema), register);
router.post("/login", validate(loginSchema), login);
router.get("/me", requireAuth, getMe);

export default router;

