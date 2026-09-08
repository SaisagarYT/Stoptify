import express from "express";
import cors from "cors";
import { config } from "./config/env.js";
import { sendSuccess } from "./utils/response.js";
import { errorHandler, notFoundHandler } from "./middlewares/errorHandler.js";
import authRoutes from "./routes/authRoutes.js";
import skillRoutes from "./routes/skillRoutes.js";
import roadmapRoutes from "./routes/roadmapRoutes.js";
import assessmentRoutes from "./routes/assessmentRoutes.js";

const app = express();

app.use(cors({ origin: config.corsOrigin }));
app.use(express.json());

app.get("/health", (req, res) => {
  return sendSuccess(res, {
    status: "healthy",
    environment: config.nodeEnv,
    service: "Stoptify Backend API",
  }, "Server is healthy");
});

app.use("/api/auth", authRoutes);
app.use("/api/skills", skillRoutes);
app.use("/api/roadmap", roadmapRoutes);
app.use("/api/roadmaps", roadmapRoutes);
app.use("/api/assessments", assessmentRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

if (config.nodeEnv !== "test") {
  app.listen(config.port, () => {
    console.log(`Stoptify server running on http://localhost:${config.port}`);
  });
}

export default app;
