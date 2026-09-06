import { sendError } from "../utils/response.js";
import { config } from "../config/env.js";

// Global error handling middleware to catch unhandled errors
export const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal Server Error";
  const errorDetails = config.nodeEnv === "development" ? err.stack : undefined;

  return sendError(res, message, statusCode, errorDetails);
};

// 404 handler for routes that do not exist
export const notFoundHandler = (req, res) => {
  return sendError(res, `Route '${req.originalUrl}' not found.`, 404);
};

