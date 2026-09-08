import { randomUUID } from "crypto";

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

export const assessments = [
  {
    id: "e5f6a1b2-c3d4-4e5f-2a3b-4c5d6e7f8a9b",
    topic_id: "b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e",
    type: "oral_exam",
    questions: [
      {
        tier: "eli5_core",
        question: "In plain English, what does it mean for an HTTP method to be idempotent? Give an example.",
        duration_seconds: 30,
      },
      {
        tier: "tradeoff_edge_case",
        question: "If PUT is idempotent and POST is not, why not use PUT for every data creation request?",
        duration_seconds: 45,
      },
      {
        tier: "real_world_application",
        question: "A user clicks Pay Now twice within 100ms. How do you prevent charging them twice?",
        duration_seconds: 45,
      },
    ],
    grading_rubric: {
      eli5_keywords: ["same state", "repeat", "side effect"],
      tradeoff_keywords: ["uri", "identifier", "resource"],
      application_keywords: ["idempotency key", "token", "unique constraint"],
    },
    passing_score_threshold: 80,
    time_limit_seconds: 180,
    is_active: true,
    created_at: new Date().toISOString(),
  },
  {
    id: "f6a1b2c3-d4e5-4f6a-3b4c-5d6e7f8a9b0c",
    topic_id: "b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e",
    type: "mcq",
    questions: [
      {
        id: "q1",
        prompt: "Which of the following HTTP methods is considered idempotent by specification?",
        options: ["POST", "PATCH", "PUT", "CONNECT"],
        correct_index: 2,
        explanation: "PUT is idempotent because multiple identical requests have the exact same server state as a single request.",
      },
      {
        id: "q2",
        prompt: "Which status code should be returned when a resource is successfully created?",
        options: ["200 OK", "201 Created", "204 No Content", "202 Accepted"],
        correct_index: 1,
        explanation: "201 Created signals that the request succeeded and a new resource was created.",
      },
    ],
    grading_rubric: {},
    passing_score_threshold: 80,
    time_limit_seconds: 120,
    is_active: true,
    created_at: new Date().toISOString(),
  }
];

export const userAssessmentResults = [];
export const oralExamSessions = [];

export const findUserByEmail = (email) => {
  return users.find((u) => u.email.toLowerCase() === email.toLowerCase());
};

export const findUserById = (id) => {
  return users.find((u) => u.id === id);
};

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

export const getSkillsByUserId = (userId) => {
  return userSkills.filter((s) => s.user_id === userId);
};

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

export const findRoadmapByIdOrSlug = (idOrSlug) => {
  return roadmaps.find((r) => r.id === idOrSlug || r.slug === idOrSlug);
};

export const findTopicsByRoadmapId = (roadmapId) => {
  return topics
    .filter((t) => t.roadmap_id === roadmapId)
    .sort((a, b) => a.order_index - b.order_index);
};

export const findUserRoadmap = (userId, roadmapId) => {
  return userRoadmaps.find((ur) => ur.user_id === userId && ur.roadmap_id === roadmapId);
};

// Enrolls user in roadmap and unlocks first topic
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

// Updates topic status and unlocks subsequent topic if completed
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

export const getAssessmentsByTopicId = (topicId) => {
  return assessments.filter((a) => a.topic_id === topicId && a.is_active);
};

export const getAssessmentById = (id) => {
  return assessments.find((a) => a.id === id && a.is_active);
};

export const getUserTopicProgressRecord = (userId, topicId) => {
  const targetTopic = topics.find((t) => t.id === topicId);
  if (!targetTopic) return null;

  const userRoadmap = findUserRoadmap(userId, targetTopic.roadmap_id);
  if (!userRoadmap) return null;

  const progress = userTopicProgress.find(
    (p) => p.user_roadmap_id === userRoadmap.id && p.topic_id === topicId
  );

  return { userRoadmap, progress, topic: targetTopic };
};

export const recordAssessmentResult = ({
  userTopicProgressId,
  assessmentId,
  score,
  feedback,
  userAnswersSnapshot,
  passed,
  aiExaminerId = "ai-evaluator-v1",
}) => {
  const result = {
    id: randomUUID(),
    user_topic_progress_id: userTopicProgressId,
    assessment_id: assessmentId,
    score,
    feedback,
    user_answers_snapshot: userAnswersSnapshot,
    completed_at: new Date().toISOString(),
    passed,
    ai_examiner_id: aiExaminerId,
    created_at: new Date().toISOString(),
  };

  userAssessmentResults.push(result);

  const topicProgress = userTopicProgress.find((p) => p.id === userTopicProgressId);
  if (topicProgress) {
    topicProgress.attempts_count += 1;
    topicProgress.last_accessed = new Date().toISOString();
  }

  return result;
};

export const recordOralExamSession = ({
  userAssessmentResultId,
  audioRecordingUrl = "",
  transcript = "",
  aiEvaluation = {},
  confidenceScore = 0.9,
  sessionStatus = "completed",
}) => {
  const session = {
    id: randomUUID(),
    user_assessment_result_id: userAssessmentResultId,
    audio_recording_url: audioRecordingUrl,
    transcript,
    ai_evaluation: aiEvaluation,
    confidence_score: confidenceScore,
    session_status: sessionStatus,
    session_date: new Date().toISOString(),
    created_at: new Date().toISOString(),
  };

  oralExamSessions.push(session);
  return session;
};
