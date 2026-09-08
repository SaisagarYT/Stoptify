import app from "../src/index.js";

async function runRagTests() {
  const PORT = 5059;
  const server = app.listen(PORT, async () => {
    try {
      const baseUrl = `http://localhost:${PORT}`;

      // 1. Register user and get auth token
      const authRes = await fetch(`${baseUrl}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "rag_researcher@example.com",
          password: "password123",
          fullName: "RAG Researcher",
        }),
      });
      const authData = await authRes.json();
      const token = authData.data.token;

      // 2. Upload study notes
      const notesContent = `Understanding RESTful API Idempotency in Payment Gateways.\n\nAlways pass a unique Idempotency-Key header when requesting financial charges. The server saves the initial transaction state so that duplicate requests return the same result.\n\nDatabase indexing with B-Trees gives fast logarithmic read speeds but adds split overhead to writes.`;

      const uploadRes = await fetch(`${baseUrl}/api/rag/upload`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          fileName: "api_design_notes.md",
          fileType: "markdown",
          content: notesContent,
        }),
      });
      const uploadData = await uploadRes.json();
      if (!uploadData.success || uploadData.data.chunksCount < 2) {
        throw new Error("Document upload or chunking failed");
      }

      // 3. Fetch user uploads list
      const listRes = await fetch(`${baseUrl}/api/rag/uploads`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const listData = await listRes.json();
      if (!listData.success || listData.data.length === 0) {
        throw new Error("Failed to list uploads");
      }

      // 4. Perform RAG search for idempotency
      const searchRes = await fetch(`${baseUrl}/api/rag/search`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          query: "Idempotency-Key header financial charges duplicate",
          limit: 3,
        }),
      });
      const searchData = await searchRes.json();
      if (!searchData.success || searchData.data.matchCount === 0) {
        throw new Error("RAG search failed to match relevant chunk");
      }

      // 5. Fetch generated textbook chapter for topic 1
      const topicId = "b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e";
      const contentRes = await fetch(`${baseUrl}/api/rag/content/${topicId}`);
      const contentData = await contentRes.json();
      if (!contentData.success || contentData.data.length === 0) {
        throw new Error("Failed to fetch generated textbook content");
      }

      console.log("All RAG document ingestion, chunking, and semantic search tests passed successfully.");
      server.close();
      process.exit(0);
    } catch (err) {
      console.error("RAG test failed:", err.message);
      server.close();
      process.exit(1);
    }
  });
}

runRagTests();

