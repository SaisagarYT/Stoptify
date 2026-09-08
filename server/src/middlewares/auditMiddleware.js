import { createAuditLog } from "../db/inMemoryStore.js";
import { supabase, isDatabaseConnected } from "../config/db.js";

// Sanitizes request payload by removing sensitive fields
const sanitizePayload = (body = {}) => {
  const sanitized = { ...body };
  delete sanitized.password;
  delete sanitized.token;
  delete sanitized.encrypted_password;
  return sanitized;
};

// Records user and system actions into system audit logs
export const recordAuditLog = (actionType) => {
  return (req, res, next) => {
    res.on("finish", async () => {
      const userId = req.user?.id || req.body?.userId || null;
      const ipAddress = req.ip || req.headers["x-forwarded-for"] || "127.0.0.1";
      const userAgent = req.headers["user-agent"] || "unknown";
      const payload = {
        method: req.method,
        path: req.originalUrl,
        statusCode: res.statusCode,
        data: sanitizePayload(req.body),
      };

      createAuditLog({
        userId,
        actionType,
        payload,
        ipAddress,
        userAgent,
      });

      if (isDatabaseConnected && supabase) {
        try {
          await supabase.from("system_audit_logs").insert([
            {
              user_id: userId,
              action_type: actionType,
              payload,
              ip_address: typeof ipAddress === "string" ? ipAddress.slice(0, 45) : "127.0.0.1",
              user_agent: typeof userAgent === "string" ? userAgent.slice(0, 255) : "unknown",
            },
          ]);
        } catch (err) {
          try {
            await supabase.from("system_audit_logs").insert([
              {
                user_id: null,
                action_type: actionType,
                payload,
                ip_address: typeof ipAddress === "string" ? ipAddress.slice(0, 45) : "127.0.0.1",
                user_agent: typeof userAgent === "string" ? userAgent.slice(0, 255) : "unknown",
              },
            ]);
          } catch (fallbackErr) {
            // Ignore audit insert error
          }
        }
      }
    });

    next();
  };
};
