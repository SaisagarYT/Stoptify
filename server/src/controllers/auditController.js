import { getAuditLogs } from "../db/inMemoryStore.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import { sendSuccess, sendError } from "../utils/response.js";

// Retrieves audit logs for the authenticated user or system
export const getAuditHistory = async (req, res) => {
  try {
    const userId = req.user?.id || null;
    const limit = parseInt(req.query.limit, 10) || 50;

    const localLogs = getAuditLogs(userId, limit);
    if (localLogs.length > 0) {
      return sendSuccess(res, localLogs, "Audit logs retrieved successfully.");
    }

    if (isDatabaseConnected && supabase) {
      let query = supabase
        .from("system_audit_logs")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(limit);

      if (userId) {
        query = query.eq("user_id", userId);
      }

      const { data, error } = await query;
      if (!error && data) {
        return sendSuccess(res, data, "Audit logs retrieved successfully.");
      }
    }

    return sendSuccess(res, localLogs, "Audit logs retrieved successfully.");
  } catch (error) {
    return sendError(res, "Failed to retrieve audit logs.", 500, error.message);
  }
};
