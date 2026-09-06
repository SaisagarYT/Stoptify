import express from "express";
import { z } from "zod";
import { getUserSkills, saveSkill } from "../controllers/skillController.js";
import { validate } from "../middlewares/validate.js";
import { requireAuth } from "../middlewares/authMiddleware.js";

const router = express.Router();

// Simple skill validation schema
const skillSchema = z.object({
  skillName: z.string().min(1, { message: "Skill name is required." }),
  proficiencyLevel: z.number().int().min(1).max(5, { message: "Proficiency must be between 1 and 5." }),
});

// All skill routes require authentication
router.use(requireAuth);

router.get("/", getUserSkills);
router.post("/", validate(skillSchema), saveSkill);

export default router;

