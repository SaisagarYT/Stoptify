import { randomUUID } from "crypto";

// In-memory data collections matching the PostgreSQL schema
export const users = [];
export const userSkills = [];

// Helper to find a user by email
export const findUserByEmail = (email) => {
  return users.find((u) => u.email.toLowerCase() === email.toLowerCase());
};

// Helper to find a user by ID
export const findUserById = (id) => {
  return users.find((u) => u.id === id);
};

// Helper to create a new user record
export const createUser = ({ email, encrypted_password, full_name }) => {
  const newUser = {
    id: randomUUID(),
    email: email.toLowerCase(),
    encrypted_password,
    full_name,
    avatar_url: "",
    preferences: { theme: "system", daily_goal_minutes: 30 },
    is_active: true,
    last_login_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    deleted_at: null,
  };
  users.push(newUser);
  return newUser;
};

// Helper to get skills for a user
export const getSkillsByUserId = (userId) => {
  return userSkills.filter((s) => s.user_id === userId);
};

// Helper to add or update a skill for a user
export const upsertSkill = ({ userId, skillName, proficiencyLevel }) => {
  const existingIndex = userSkills.findIndex(
    (s) => s.user_id === userId && s.skill_name.toLowerCase() === skillName.toLowerCase()
  );

  if (existingIndex !== -1) {
    userSkills[existingIndex].proficiency_level = proficiencyLevel;
    userSkills[existingIndex].assessed_at = new Date().toISOString();
    return userSkills[existingIndex];
  }

  const newSkill = {
    id: randomUUID(),
    user_id: userId,
    skill_name: skillName,
    proficiency_level: proficiencyLevel,
    assessed_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
  };

  userSkills.push(newSkill);
  return newSkill;
};

