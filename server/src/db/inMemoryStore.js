import { randomUUID } from "crypto";

// In-memory data collections matching the PostgreSQL schema
export const users = [];
export const userSkills = [];
export const roadmaps = [
  {
    id: "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
    title: "Backend Engineering & Distributed Systems",
    slug: "backend-mastery",
    target_career: "Backend Engineer / Cloud Architect",
    duration_weeks: 6,
    difficulty_level: "Intermediate",
    structure_template: {},
    is_public: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }
];

export const topics = [
  {
    id: "b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e",
    roadmap_id: "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
    title: "HTTP Protocol & RESTful API Architecture",
    slug: "http-protocol-rest-api",
    description: "Master HTTP status codes, headers, and idempotent vs non-idempotent methods.",
    order_index: 1,
    estimated_duration_min: "30 min",
    definition_of_done: {
      conceptual: "Explain idempotent vs non-idempotent HTTP methods in plain English.",
      practical: "Build an Express endpoint with validation using proper status codes.",
      anti_scope: "Do not study HTTP/3, gRPC, or QUIC internals yet.",
    },
    anti_scope: ["HTTP/3", "gRPC", "QUIC internals"],
    prerequisites_ids: [],
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: "c3d4e5f6-a1b2-4c5d-0e1f-2a3b4c5d6e7f",
    roadmap_id: "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
    title: "Relational Database Indexing & Query Plans",
    slug: "database-indexing-query-plans",
    description: "Understand B-tree indexes, write overhead, and EXPLAIN ANALYZE execution plans.",
    order_index: 2,
    estimated_duration_min: "45 min",
    definition_of_done: {
      conceptual: "Explain B-tree index lookups vs full table scans in under 2 minutes.",
      practical: "Run an EXPLAIN ANALYZE query to verify index scan vs sequence scan.",
      anti_scope: "Do not write custom GiST or SP-GiST index implementations yet.",
    },
    anti_scope: ["GiST custom indexes", "SP-GiST"],
    prerequisites_ids: ["b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e"],
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: "d4e5f6a1-b2c3-4d5e-1f2a-3b4c5d6e7f8a",
    roadmap_id: "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
    title: "Caching Strategies & Redis Fundamentals",
    slug: "caching-strategies-redis",
    description: "Learn Cache-Aside and Write-Through caching patterns with TTL expiry.",
    order_index: 3,
    estimated_duration_min: "40 min",
    definition_of_done: {
      conceptual: "Articulate Cache-Aside vs Write-Through caching patterns and trade-offs.",
      practical: "Implement a Redis caching layer around a database query with TTL.",
      anti_scope: "Avoid multi-region Redis Cluster sharding at this stage.",
    },
    anti_scope: ["Redis Cluster multi-region", "Raft consensus"],
    prerequisites_ids: ["c3d4e5f6-a1b2-4c5d-0e1f-2a3b4c5d6e7f"],
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
];

export const userRoadmaps = [];
export const userTopicProgress = [];

// Helper to find a user by email
export const findUserByEmail = (email) => {
  return users.find((u) => u.email.toLowerCase() === email.toLowerCase());
};

// Helper to find a user by ID
export const findUserById = (id) => {
  return users.find((u) => u.id === id);
};

// Helper to create a new user record
export const createUser = ({ email, encrypted_password, full_name }) => {
  const newUser = {
    id: randomUUID(),
    email: email.toLowerCase(),
    encrypted_password,
    full_name,
    avatar_url: "",
    preferences: { theme: "system", daily_goal_minutes: 30 },
    is_active: true,
    last_login_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    deleted_at: null,
  };
  users.push(newUser);
  return newUser;
};

// Helper to get skills for a user
export const getSkillsByUserId = (userId) => {
  return userSkills.filter((s) => s.user_id === userId);
};

// Helper to add or update a skill for a user
export const upsertSkill = ({ userId, skillName, proficiencyLevel }) => {
  const existingIndex = userSkills.findIndex(
    (s) => s.user_id === userId && s.skill_name.toLowerCase() === skillName.toLowerCase()
  );

  if (existingIndex !== -1) {
    userSkills[existingIndex].proficiency_level = proficiencyLevel;
    userSkills[existingIndex].assessed_at = new Date().toISOString();
    return userSkills[existingIndex];
  }

  const newSkill = {
    id: randomUUID(),
    user_id: userId,
    skill_name: skillName,
    proficiency_level: proficiencyLevel,
    assessed_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
  };

  userSkills.push(newSkill);
  return newSkill;
};

// Helper to find a roadmap by id or slug
export const findRoadmapByIdOrSlug = (idOrSlug) => {
  return roadmaps.find((r) => r.id === idOrSlug || r.slug === idOrSlug);
};

// Helper to get ordered topics for a roadmap
export const findTopicsByRoadmapId = (roadmapId) => {
  return topics
    .filter((t) => t.roadmap_id === roadmapId)
    .sort((a, b) => a.order_index - b.order_index);
};

// Helper to find enrollment record
export const findUserRoadmap = (userId, roadmapId) => {
  return userRoadmaps.find((ur) => ur.user_id === userId && ur.roadmap_id === roadmapId);
};

// Enrolls user into a roadmap and unlocks the first topic
export const enrollUserInRoadmap = (userId, roadmapId) => {
  const existing = findUserRoadmap(userId, roadmapId);
  if (existing) return existing;

  const userRoadmap = {
    id: randomUUID(),
    user_id: userId,
    roadmap_id: roadmapId,
    status: "in_progress",
    overall_progress_percent: 0.0,
    started_at: new Date().toISOString(),
    last_accessed_at: new Date().toISOString(),
    completed_at: null,
    created_at: new Date().toISOString(),
  };

  userRoadmaps.push(userRoadmap);

  const roadmapTopics = findTopicsByRoadmapId(roadmapId);
  roadmapTopics.forEach((topic, index) => {
    userTopicProgress.push({
      id: randomUUID(),
      user_roadmap_id: userRoadmap.id,
      topic_id: topic.id,
      status: index === 0 ? "in_progress" : "locked",
      attempts_count: 0,
      last_accessed: index === 0 ? new Date().toISOString() : null,
      started_at: index === 0 ? new Date().toISOString() : null,
      completed_at: null,
      created_at: new Date().toISOString(),
    });
  });

  return userRoadmap;
};

// Fetches user progress for all topics in a roadmap
export const getStudentRoadmapProgress = (userId, roadmapId) => {
  const userRoadmap = findUserRoadmap(userId, roadmapId);
  if (!userRoadmap) return null;

  const topicProgress = userTopicProgress.filter((p) => p.user_roadmap_id === userRoadmap.id);
  const roadmapTopics = findTopicsByRoadmapId(roadmapId);

  const topicDetails = roadmapTopics.map((topic) => {
    const progress = topicProgress.find((p) => p.topic_id === topic.id);
    return {
      ...topic,
      userProgress: progress || { status: "locked", attempts_count: 0 },
    };
  });

  return {
    enrollment: userRoadmap,
    topics: topicDetails,
  };
};

// Updates a topic's status and automatically unlocks the next topic if completed
export const updateStudentTopicStatus = (userId, roadmapId, topicId, status) => {
  const userRoadmap = findUserRoadmap(userId, roadmapId);
  if (!userRoadmap) return null;

  const currentTopic = userTopicProgress.find(
    (p) => p.user_roadmap_id === userRoadmap.id && p.topic_id === topicId
  );
  if (!currentTopic) return null;

  currentTopic.status = status;
  currentTopic.last_accessed = new Date().toISOString();
  if (status === "completed") {
    currentTopic.completed_at = new Date().toISOString();
  }

  const roadmapTopics = findTopicsByRoadmapId(roadmapId);
  const currentIndex = roadmapTopics.findIndex((t) => t.id === topicId);

  // Unlock next topic if current topic completed
  if (status === "completed" && currentIndex + 1 < roadmapTopics.length) {
    const nextTopicId = roadmapTopics[currentIndex + 1].id;
    const nextProgress = userTopicProgress.find(
      (p) => p.user_roadmap_id === userRoadmap.id && p.topic_id === nextTopicId
    );
    if (nextProgress && nextProgress.status === "locked") {
      nextProgress.status = "in_progress";
      nextProgress.started_at = new Date().toISOString();
    }
  }

  // Recalculate overall progress percentage
  const totalTopics = roadmapTopics.length;
  const completedCount = userTopicProgress.filter(
    (p) => p.user_roadmap_id === userRoadmap.id && p.status === "completed"
  ).length;

  userRoadmap.overall_progress_percent = totalTopics > 0
    ? Math.round((completedCount / totalTopics) * 100 * 10) / 10
    : 0.0;

  if (completedCount === totalTopics) {
    userRoadmap.status = "completed";
    userRoadmap.completed_at = new Date().toISOString();
  }

  userRoadmap.last_accessed_at = new Date().toISOString();

  return {
    userRoadmap,
    updatedTopic: currentTopic,
  };
};
