import app from "../src/index.js";

async function runAssessmentTests() {
  const PORT = 5058;
  const server = app.listen(PORT, async () => {
    try {
      const baseUrl = `http://localhost:${PORT}`;

      // 1. Register student and get token
      const authRes = await fetch(`${baseUrl}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "feynman_student@example.com",
          password: "password123",
          fullName: "Richard Learner",
        }),
      });
      const authData = await authRes.json();
      const token = authData.data.token;

      // 2. Fetch roadmaps and enroll
      const roadmapsRes = await fetch(`${baseUrl}/api/roadmaps`);
      const roadmapsData = await roadmapsRes.json();
      const roadmap = roadmapsData.data[0];

      const enrollRes = await fetch(`${baseUrl}/api/roadmaps/${roadmap.id}/enroll`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
      });
      const enrollData = await enrollRes.json();
      if (!enrollData.success) throw new Error("Enrollment failed");

      // 3. Fetch topic assessments
      const topicDetailRes = await fetch(`${baseUrl}/api/roadmaps/${roadmap.slug}`);
      const topicDetailData = await topicDetailRes.json();
      const firstTopic = topicDetailData.data.topics[0];

      const assessRes = await fetch(`${baseUrl}/api/assessments/topic/${firstTopic.id}`);
      const assessData = await assessRes.json();
      if (!assessData.success || assessData.data.length < 2) {
        throw new Error("Failed to fetch assessments for topic");
      }

      const oralAssessment = assessData.data.find((a) => a.type === "oral_exam");
      const mcqAssessment = assessData.data.find((a) => a.type === "mcq");

      // 4. Start oral examination
      const startOralRes = await fetch(`${baseUrl}/api/assessments/oral/start`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ topicId: firstTopic.id }),
      });
      const startOralData = await startOralRes.json();
      if (!startOralData.success || startOralData.data.probes.length !== 3) {
        throw new Error("Oral exam start failed to return 3 probes");
      }

      // 5. Evaluate oral defense with passing answers
      const evalRes = await fetch(`${baseUrl}/api/assessments/oral/evaluate`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          assessmentId: oralAssessment.id,
          transcript: "Repeating an idempotent request leaves the system in the exact same state without unintended side effects. PUT requires knowing the full URI resource identifier while POST lets server create it. To prevent double payments, we use a unique idempotency key token on the endpoint.",
        }),
      });
      const evalData = await evalRes.json();
      if (!evalData.success || !evalData.data.passed || evalData.data.score < 80) {
        throw new Error(`Oral defense evaluation failed: ${JSON.stringify(evalData)}`);
      }

      // 6. Verify sequential progression: Topic 1 completed, Topic 2 unlocked
      const progressRes = await fetch(`${baseUrl}/api/roadmaps/${roadmap.id}/progress`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const progressData = await progressRes.json();
      const topicsList = progressData.data.topics;

      if (topicsList[0].userProgress.status !== "completed") {
        throw new Error("Topic 1 should be completed after passing oral defense");
      }
      if (topicsList[1].userProgress.status !== "in_progress") {
        throw new Error("Topic 2 should be unlocked to in_progress after passing Topic 1");
      }

      // 7. Test MCQ submission
      const mcqRes = await fetch(`${baseUrl}/api/assessments/${mcqAssessment.id}/submit-mcq`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          answers: [
            { questionIndex: 0, selectedIndex: 2 }, // PUT is correct
            { questionIndex: 1, selectedIndex: 1 }, // 201 Created is correct
          ],
        }),
      });
      const mcqResult = await mcqRes.json();
      if (!mcqResult.success || mcqResult.data.score !== 100 || !mcqResult.data.passed) {
        throw new Error(`MCQ submission failed: ${JSON.stringify(mcqResult)}`);
      }

      console.log("All multi-modal assessment and oral defense tests passed successfully.");
      server.close();
      process.exit(0);
    } catch (err) {
      console.error("Assessment test failed:", err.message);
      server.close();
      process.exit(1);
    }
  });
}

runAssessmentTests();

