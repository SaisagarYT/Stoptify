// Helper to send standardized success responses
export const sendSuccess = (res, data = null, message = "Success", statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

// Helper to send standardized error responses
export const sendError = (res, message = "An error occurred", statusCode = 500, error = null) => {
  return res.status(statusCode).json({
    success: false,
    message,
    ...(error ? { error } : {}),
  });
};

