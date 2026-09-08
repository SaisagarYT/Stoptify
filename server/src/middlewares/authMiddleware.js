import jwt from "jsonwebtoken";
import { config } from "../config/env.js";
import { sendError } from "../utils/response.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import { findUserById } from "../db/inMemoryStore.js";

// Verifies JWT token and attaches user to request
export const requireAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return sendError(res, "Access denied. No token provided.", 401);
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, config.jwtSecret);
    let user = null;

    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("users")
        .select("*")
        .eq("id", decoded.id)
        .maybeSingle();
      user = data;
    }

    if (!user) {
      user = findUserById(decoded.id);
    }

    if (!user || !user.is_active) {
      return sendError(res, "User not found or account is deactivated.", 401);
    }

    req.user = {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
    };

    next();
  } catch (error) {
    return sendError(res, "Invalid or expired token.", 401, error.message);
  }
};
