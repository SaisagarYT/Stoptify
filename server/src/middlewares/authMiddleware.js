import jwt from "jsonwebtoken";
import { config } from "../config/env.js";
import { sendError } from "../utils/response.js";
import { findUserById } from "../db/inMemoryStore.js";

// Middleware to verify JWT token and attach user to request
export const requireAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;

  // Check if Authorization header exists and follows 'Bearer <token>' pattern
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return sendError(res, "Access denied. No token provided.", 401);
  }

  const token = authHeader.split(" ")[1];

  try {
    // Verify token validity against our secret key
    const decoded = jwt.verify(token, config.jwtSecret);
    const user = findUserById(decoded.id);

    if (!user || !user.is_active) {
      return sendError(res, "User not found or account is deactivated.", 401);
    }

    // Attach user payload to request for downstream route handlers
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

