import { sendError } from "../utils/response.js";

// Validates incoming request data using simple Zod schemas
export const validate = (schema, source = "body") => {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);

    if (!result.success) {
      const issues = result.error.issues || [];
      const errors = issues.map((err) => ({
        field: err.path.join(".") || "root",
        message: err.message,
      }));

      return sendError(res, "Validation failed", 400, errors);
    }

    req[source] = result.data;
    next();
  };
};

