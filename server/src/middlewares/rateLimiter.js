import { checkRateLimit } from "../db/inMemoryStore.js";
import { sendError } from "../utils/response.js";
import { supabase, isDatabaseConnected } from "../config/db.js";

// Rate limiting middleware to protect endpoints from abuse
export const rateLimiter = ({
  windowMs = 60000,
  maxRequests = 60,
  message = "Too many requests. Please slow down and try again later.",
} = {}) => {
  return async (req, res, next) => {
    const rawIp = req.ip || req.headers["x-forwarded-for"] || req.socket.remoteAddress || "127.0.0.1";
    const ipString = Array.isArray(rawIp) ? rawIp[0] : String(rawIp);
    const identifier = req.user?.id ? `user:${req.user.id}` : `ip:${ipString}`;

    const limitResult = checkRateLimit(identifier, windowMs, maxRequests);

    res.setHeader("X-RateLimit-Limit", maxRequests);
    res.setHeader("X-RateLimit-Remaining", limitResult.remaining);
    res.setHeader("X-RateLimit-Reset", Math.ceil(limitResult.resetMs / 1000));

    if (!limitResult.allowed) {
      return sendError(res, message, 429, {
        retryAfterSeconds: Math.ceil(limitResult.resetMs / 1000),
      });
    }

    if (isDatabaseConnected && supabase) {
      try {
        await supabase
          .from("api_rate_limits")
          .upsert(
            {
              identifier: identifier.slice(0, 150),
              request_count: maxRequests - limitResult.remaining,
              window_start: new Date().toISOString(),
            },
            { onConflict: "identifier" }
          );
      } catch (err) {
        // Non-blocking background sync error
      }
    }

    next();
  };
};
