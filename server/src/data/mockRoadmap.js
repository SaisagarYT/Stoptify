// mockRoadmap.js - Sample seed data representing our curriculum nodes
// In production, this will be dynamically retrieved from Supabase and Pinecone RAG.

export const sampleRoadmap = {
  id: "backend-mastery",
  title: "Backend Engineering & System Design",
  description: "A mastery-driven roadmap focusing on practical verification over passive watching.",
  milestones: [
    {
      id: "node-1",
      title: "HTTP Protocol & RESTful API Architecture",
      tier: "Beginner",
      status: "completed", // First node is already completed for demonstration
      estimatedMinutes: 30,
      definitionOfDone: {
        conceptual: "Explain the difference between idempotent and non-idempotent HTTP methods in plain English.",
        practical: "Build a minimal Express endpoint with query parameter validation using status codes correctly (200, 201, 400, 404).",
        antiScope: "Do not worry about HTTP/3, gRPC, or QUIC protocol internals at this stage."
      },
      prerequisites: []
    },
    {
      id: "node-2",
      title: "Relational Database Indexing & Query Plans",
      tier: "Intermediate",
      status: "in_progress", // Current active milestone
      estimatedMinutes: 45,
      definitionOfDone: {
        conceptual: "Explain how B-tree index lookups work versus full table scans in under 2 minutes.",
        practical: "Run an EXPLAIN ANALYZE query on a table of 10,000 rows to verify an index scan is triggered.",
        antiScope: "Do not attempt custom GiST or SP-GiST index implementations yet."
      },
      prerequisites: ["node-1"]
    },
    {
      id: "node-3",
      title: "Caching Strategies & Redis Fundamentals",
      tier: "Intermediate",
      status: "locked",
      estimatedMinutes: 40,
      definitionOfDone: {
        conceptual: "Articulate Cache-Aside vs Write-Through caching patterns and their trade-offs.",
        practical: "Implement a Redis caching layer around a slow database read with a 60-second TTL.",
        antiScope: "Avoid Redis Cluster sharding and multi-region replication setups."
      },
      prerequisites: ["node-2"]
    }
  ]
};
