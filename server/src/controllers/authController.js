import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { config } from "../config/env.js";
import { sendSuccess, sendError } from "../utils/response.js";
import { findUserByEmail, findUserById, createUser } from "../db/inMemoryStore.js";

// Generates a signed JWT token valid for 7 days
const generateToken = (user) => {
  return jwt.sign(
    { id: user.id, email: user.email },
    config.jwtSecret,
    { expiresIn: "7d" }
  );
};

// Formats safe user data without exposing password hash
const formatUserResponse = (user) => {
  const { encrypted_password, ...safeUser } = user;
  return safeUser;
};

// Register a new student account
export const register = async (req, res) => {
  try {
    const { email, password, fullName } = req.body;

    // Check if account with email already exists
    const existingUser = findUserByEmail(email);
    if (existingUser) {
      return sendError(res, "An account with this email already exists.", 400);
    }

    // Encrypt password using bcrypt with salt rounds of 10
    const encrypted_password = await bcrypt.hash(password, 10);

    const newUser = createUser({
      email,
      encrypted_password,
      full_name: fullName,
    });

    const token = generateToken(newUser);

    return sendSuccess(
      res,
      { user: formatUserResponse(newUser), token },
      "Account registered successfully.",
      201
    );
  } catch (error) {
    return sendError(res, "Registration failed.", 500, error.message);
  }
};

// Log in an existing user
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = findUserByEmail(email);
    if (!user || !user.is_active) {
      return sendError(res, "Invalid email or password.", 401);
    }

    // Compare supplied password with encrypted password in store
    const isMatch = await bcrypt.compare(password, user.encrypted_password);
    if (!isMatch) {
      return sendError(res, "Invalid email or password.", 401);
    }

    user.last_login_at = new Date().toISOString();
    const token = generateToken(user);

    return sendSuccess(
      res,
      { user: formatUserResponse(user), token },
      "Login successful."
    );
  } catch (error) {
    return sendError(res, "Login failed.", 500, error.message);
  }
};

// Fetch profile of the currently logged-in user
export const getMe = (req, res) => {
  try {
    const user = findUserById(req.user.id);
    if (!user) {
      return sendError(res, "User profile not found.", 404);
    }

    return sendSuccess(res, formatUserResponse(user), "Profile retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve profile.", 500, error.message);
  }
};

