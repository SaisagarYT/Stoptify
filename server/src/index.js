import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import roadmapRoutes from "./routes/roadmapRoutes.js";

// Load environment variables from .env
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Standard Middlewares
app.use(cors()); // Allow Flutter app to connect from local emulator / device
app.use(express.json()); // Parse JSON request bodies

// Health Check Endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    service: "Stoptify Backend API"
  });
});

// API Routes
app.use("/api/roadmap", roadmapRoutes);

// Fallback 404 handler for undefined routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route '${req.originalUrl}' not found on Stoptify server.`
  });
});

// Global Error Handling Middleware
app.use((err, req, res, next) => {
  console.error("Server Error:", err.stack);
  res.status(500).json({
    success: false,
    message: "Internal Server Error",
    error: err.message
  });
});

// Start Server
app.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(`Stoptify Backend running on port ${PORT}`);
  console.log(`Health Check: http://localhost:${PORT}/health`);
  console.log(`Roadmap API: http://localhost:${PORT}/api/roadmap`);
  console.log(`=========================================`);
});
