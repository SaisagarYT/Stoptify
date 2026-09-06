import express from "express";
import cors from "cors";
import { config } from "./config/env.js";
import { sendSuccess } from "./utils/response.js";
import { errorHandler, notFoundHandler } from "./middlewares/errorHandler.js";
import authRoutes from "./routes/authRoutes.js";
import skillRoutes from "./routes/skillRoutes.js";
import roadmapRoutes from "./routes/roadmapRoutes.js";

const app = express();

// Standard middlewares
app.use(cors({ origin: config.corsOrigin }));
app.use(express.json());

// Server health check
app.get("/health", (req, res) => {
  return sendSuccess(res, {
    status: "healthy",
    environment: config.nodeEnv,
    service: "Stoptify Backend API",
  }, "Server is healthy");
});

// API routes
app.use("/api/auth", authRoutes);
app.use("/api/skills", skillRoutes);
app.use("/api/roadmap", roadmapRoutes);

// Fallback for non-existent routes
app.use(notFoundHandler);

// Central error handling
app.use(errorHandler);

// Start server
if (config.nodeEnv !== "test") {
  app.listen(config.port, () => {
    console.log(`Stoptify server running on http://localhost:${config.port}`);
  });
}

export default app;
