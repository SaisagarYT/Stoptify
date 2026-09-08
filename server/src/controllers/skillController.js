import { sendSuccess, sendError } from "../utils/response.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import { getSkillsByUserId, upsertSkill } from "../db/inMemoryStore.js";

// Fetch all assessed skills for current user
export const getUserSkills = async (req, res) => {
  try {
    if (isDatabaseConnected && supabase) {
      const { data, error } = await supabase
        .from("user_skills")
        .select("*")
        .eq("user_id", req.user.id);

      if (!error && data && data.length > 0) {
        return sendSuccess(res, data, "User skills retrieved.");
      }
    }

    const skills = getSkillsByUserId(req.user.id);
    return sendSuccess(res, skills, "User skills retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve skills.", 500, error.message);
  }
};

// Add or update proficiency level for a skill
export const saveSkill = async (req, res) => {
  try {
    const { skillName, proficiencyLevel } = req.body;

    if (isDatabaseConnected && supabase) {
      const { data: existingSkill } = await supabase
        .from("user_skills")
        .select("*")
        .eq("user_id", req.user.id)
        .eq("skill_name", skillName)
        .maybeSingle();

      if (existingSkill) {
        const { data, error } = await supabase
          .from("user_skills")
          .update({
            proficiency_level: proficiencyLevel,
            assessed_at: new Date().toISOString(),
          })
          .eq("id", existingSkill.id)
          .select()
          .single();

        if (!error && data) {
          return sendSuccess(res, data, "Skill updated successfully.");
        }
      } else {
        const { data, error } = await supabase
          .from("user_skills")
          .insert([
            {
              user_id: req.user.id,
              skill_name: skillName,
              proficiency_level: proficiencyLevel,
            },
          ])
          .select()
          .single();

        if (!error && data) {
          return sendSuccess(res, data, "Skill updated successfully.");
        }
      }
    }

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
