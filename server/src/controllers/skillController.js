import { sendSuccess, sendError } from "../utils/response.js";
import { getSkillsByUserId, upsertSkill } from "../db/inMemoryStore.js";

// Fetch all assessed skills for current user
export const getUserSkills = (req, res) => {
  try {
    const skills = getSkillsByUserId(req.user.id);
    return sendSuccess(res, skills, "User skills retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve skills.", 500, error.message);
  }
};

// Add or update proficiency level for a skill
export const saveSkill = (req, res) => {
  try {
    const { skillName, proficiencyLevel } = req.body;

    const updatedSkill = upsertSkill({
      userId: req.user.id,
      skillName,
      proficiencyLevel,
    });

    return sendSuccess(res, updatedSkill, "Skill updated successfully.");
  } catch (error) {
    return sendError(res, "Failed to update skill.", 500, error.message);
  }
};

