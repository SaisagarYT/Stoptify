import app from "../src/index.js";

async function runCurriculumTests() {
  const PORT = 5057;
  const server = app.listen(PORT, async () => {
    try {
      const baseUrl = `http://localhost:${PORT}`;

      // 1. Register a student to get an auth token
      const authRes = await fetch(`${baseUrl}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "curriculum_learner@example.com",
          password: "password123",
          fullName: "Curriculum Tester",
        }),
      });
      const authData = await authRes.json();
      const token = authData.data.token;

      // 2. Fetch public roadmaps
      const roadmapsRes = await fetch(`${baseUrl}/api/roadmaps`);
      const roadmapsData = await roadmapsRes.json();
      if (!roadmapsData.success || roadmapsData.data.length === 0) {
        throw new Error("Failed to fetch roadmaps list");
      }
      const roadmap = roadmapsData.data[0];

      // 3. Fetch roadmap detail with 3-tier Definition of Done
      const detailRes = await fetch(`${baseUrl}/api/roadmaps/${roadmap.slug}`);
      const detailData = await detailRes.json();
      if (!detailData.success || !detailData.data.topics || detailData.data.topics.length === 0) {
        throw new Error("Failed to fetch roadmap detail with topics");
      }

      const firstTopic = detailData.data.topics[0];
      if (
        !firstTopic.definition_of_done.conceptual ||
        !firstTopic.definition_of_done.practical ||
        !firstTopic.definition_of_done.anti_scope
      ) {
        throw new Error("Topic missing 3-tier Definition of Done contract");
      }

      // 4. Enroll user into roadmap
      const enrollRes = await fetch(`${baseUrl}/api/roadmaps/${roadmap.id}/enroll`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
      });
      const enrollData = await enrollRes.json();
      if (!enrollData.success || enrollData.data.overall_progress_percent !== 0) {
        throw new Error("Roadmap enrollment failed");
      }

      // 5. Verify initial topic progression states
      const progressRes = await fetch(`${baseUrl}/api/roadmaps/${roadmap.id}/progress`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const progressData = await progressRes.json();
      const topicsList = progressData.data.topics;

      if (topicsList[0].userProgress.status !== "in_progress") {
        throw new Error("First topic should be in_progress upon enrollment");
      }
      if (topicsList[1].userProgress.status !== "locked") {
        throw new Error("Second topic should be locked initially");
      }

      // 6. Complete first topic and verify progression
      const completeRes = await fetch(
        `${baseUrl}/api/roadmaps/${roadmap.id}/topics/${firstTopic.id}`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ status: "completed" }),
        }
      );
      const completeData = await completeRes.json();
      if (!completeData.success) {
        throw new Error("Failed to update topic status");
      }

      // 7. Verify Topic 2 is unlocked and progress percentage increased
      const updatedProgressRes = await fetch(`${baseUrl}/api/roadmaps/${roadmap.id}/progress`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const updatedProgressData = await updatedProgressRes.json();
      const updatedTopics = updatedProgressData.data.topics;

      if (updatedTopics[0].userProgress.status !== "completed") {
        throw new Error("Topic 1 should be completed");
      }
      if (updatedTopics[1].userProgress.status !== "in_progress") {
        throw new Error("Topic 2 should be automatically unlocked to in_progress");
      }
      if (updatedProgressData.data.enrollment.overall_progress_percent <= 0) {
        throw new Error("Overall progress percent should be greater than 0");
      }

      console.log("All roadmap curriculum & topic progression tests passed successfully.");
      server.close();
      process.exit(0);
    } catch (err) {
      console.error("Curriculum test failed:", err.message);
      server.close();
      process.exit(1);
    }
  });
}

runCurriculumTests();
