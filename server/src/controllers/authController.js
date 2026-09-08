import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { config } from "../config/env.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import { sendSuccess, sendError } from "../utils/response.js";
import { findUserByEmail, findUserById, createUser } from "../db/inMemoryStore.js";

const generateToken = (user) => {
  return jwt.sign(
    { id: user.id, email: user.email },
    config.jwtSecret,
    { expiresIn: "7d" }
  );
};

const formatUserResponse = (user) => {
  const { encrypted_password, ...safeUser } = user;
  return safeUser;
};

// Register a new user
export const register = async (req, res) => {
  try {
    const { email, password, fullName } = req.body;

    if (isDatabaseConnected && supabase) {
      const { data: existingUser } = await supabase
        .from("users")
        .select("id, email")
        .eq("email", email)
        .maybeSingle();

      if (existingUser) {
        return sendError(res, "An account with this email already exists.", 400);
      }
    } else {
      const existingUser = findUserByEmail(email);
      if (existingUser) {
        return sendError(res, "An account with this email already exists.", 400);
      }
    }

    const encrypted_password = await bcrypt.hash(password, 10);
    let newUser = null;

    if (isDatabaseConnected && supabase) {
      const { data, error } = await supabase
        .from("users")
        .insert([
          {
            email,
            encrypted_password,
            full_name: fullName,
          },
        ])
        .select()
        .single();

      if (!error && data) {
        newUser = data;
      }
    }

    if (!newUser) {
      newUser = createUser({
        email,
        encrypted_password,
        full_name: fullName,
      });
    }

    const token = generateToken(newUser);
    req.user = { id: newUser.id, email: newUser.email, fullName: newUser.full_name };

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
    let user = null;

    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("users")
        .select("*")
        .eq("email", email)
        .maybeSingle();
      user = data;
    }

    if (!user) {
      user = findUserByEmail(email);
    }

    if (!user || !user.is_active) {
      return sendError(res, "Invalid email or password.", 401);
    }

    const isMatch = await bcrypt.compare(password, user.encrypted_password);
    if (!isMatch) {
      return sendError(res, "Invalid email or password.", 401);
    }

    if (isDatabaseConnected && supabase) {
      await supabase
        .from("users")
        .update({ last_login_at: new Date().toISOString() })
        .eq("id", user.id);
    }

    user.last_login_at = new Date().toISOString();
    const token = generateToken(user);
    req.user = { id: user.id, email: user.email, fullName: user.full_name };

    return sendSuccess(
      res,
      { user: formatUserResponse(user), token },
      "Login successful."
    );
  } catch (error) {
    return sendError(res, "Login failed.", 500, error.message);
  }
};

// Returns current authenticated user profile
export const getMe = async (req, res) => {
  try {
    let user = null;

    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("users")
        .select("*")
        .eq("id", req.user.id)
        .maybeSingle();
      user = data;
    }

    if (!user) {
      user = findUserById(req.user.id);
    }

    if (!user) {
      return sendError(res, "User not found.", 404);
    }

    return sendSuccess(res, formatUserResponse(user), "User profile retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve profile.", 500, error.message);
  }
};
