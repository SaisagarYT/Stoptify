import app from "../src/index.js";
import { validate } from "../src/middlewares/validate.js";
import { z } from "zod";

async function runTests() {
  const PORT = 5055;
  const server = app.listen(PORT, async () => {
    try {
      const baseUrl = `http://localhost:${PORT}`;

      // Test 1: Verify health endpoint
      const healthRes = await fetch(`${baseUrl}/health`);
      const healthData = await healthRes.json();
      if (!healthData.success) throw new Error("Health check failed");

      // Test 2: Verify roadmap endpoint
      const roadmapRes = await fetch(`${baseUrl}/api/roadmap`);
      const roadmapData = await roadmapRes.json();
      if (!roadmapData.success) throw new Error("Roadmap fetch failed");

      // Test 3: Verify 404 handler
      const notFoundRes = await fetch(`${baseUrl}/api/unknown-endpoint`);
      const notFoundData = await notFoundRes.json();
      if (notFoundRes.status !== 404 || notFoundData.success !== false) throw new Error("404 handler failed");

      // Test 4: Verify schema validation
      const testSchema = z.object({
        email: z.string().email(),
      });

      let statusCode = null;
      let errorPayload = null;
      const res = {
        status: (code) => {
          statusCode = code;
          return {
            json: (data) => {
              errorPayload = data;
            },
          };
        },
      };

      const middleware = validate(testSchema);
      middleware({ body: { email: "invalid-email" } }, res, () => {});

      if (statusCode !== 400 || errorPayload.success !== false) {
        throw new Error("Validation failed");
      }

      console.log("Server foundation tests passed successfully.");
      server.close();
      process.exit(0);
    } catch (err) {
      console.error("Test failed:", err.message);
      server.close();
      process.exit(1);
    }
  });
}

runTests();

