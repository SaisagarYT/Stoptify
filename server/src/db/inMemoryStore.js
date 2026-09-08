import { randomUUID } from "crypto";

export const users = [];
export const userSkills = [];
export const roadmaps = [];
export const topics = [];
export const userRoadmaps = [];
export const userTopicProgress = [];
export const assessments = [];
export const userAssessmentResults = [];
export const oralExamSessions = [];
export const userUploads = [];
export const documentChunks = [];
export const generatedContents = [];


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

// Splits text into discrete chunks along line boundaries
export const chunkAndStoreDocument = (uploadId, text, source = "Notes") => {
  const segments = text
    .split("\n\n")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  const createdChunks = segments.map((content, index) => {
    const chunk = {
      id: randomUUID(),
      upload_id: uploadId,
      content,
      chunk_index: index,
      source_page: source,
      created_at: new Date().toISOString(),
    };
    documentChunks.push(chunk);
    return chunk;
  });

  return createdChunks;
};

// Records user upload and generates its initial document chunks
export const createUpload = ({ userId, fileName, fileType = "notes", content = "" }) => {
  const upload = {
    id: randomUUID(),
    user_id: userId,
    file_name: fileName,
    file_url: `/uploads/${fileName}`,
    file_type: fileType,
    file_size_bytes: Buffer.byteLength(content, "utf8"),
    mime_type: fileType === "pdf" ? "application/pdf" : "text/plain",
    storage_path: `user_${userId}/${fileName}`,
    uploaded_at: new Date().toISOString(),
    processed_at: new Date().toISOString(),
  };

  userUploads.push(upload);

  const chunks = chunkAndStoreDocument(upload.id, content, fileName);
  return { upload, chunks };
};

export const getUserUploads = (userId) => {
  return userUploads.filter((u) => u.user_id === userId);
};

// Simple search ranking matching query keywords across document chunks
export const searchChunks = (query, limit = 5) => {
  const words = query.toLowerCase().split(" ").filter((w) => w.length > 2);

  const scored = documentChunks.map((chunk) => {
    const chunkLower = chunk.content.toLowerCase();
    let score = 0;
    words.forEach((w) => {
      if (chunkLower.includes(w)) score += 1;
    });
    return { ...chunk, score };
  });

  return scored
    .filter((c) => c.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
};

export const getGeneratedContentByTopic = (topicId) => {
  return generatedContents.filter((g) => g.topic_id === topicId);
};

export const systemAuditLogs = [];
export const apiRateLimits = new Map();

// Creates and records an audit log entry
export const createAuditLog = ({ userId = null, actionType, payload = {}, ipAddress = "127.0.0.1", userAgent = "unknown" }) => {
  const entry = {
    id: randomUUID(),
    user_id: userId,
    action_type: actionType,
    payload,
    ip_address: ipAddress,
    user_agent: userAgent,
    created_at: new Date().toISOString(),
  };
  systemAuditLogs.unshift(entry);
  return entry;
};

// Retrieves audit logs optionally filtered by user ID
export const getAuditLogs = (userId = null, limit = 50) => {
  if (userId) {
    return systemAuditLogs.filter((log) => log.user_id === userId).slice(0, limit);
  }
  return systemAuditLogs.slice(0, limit);
};

// Checks and updates request counts within a sliding time window
export const checkRateLimit = (identifier, windowMs = 60000, maxRequests = 100) => {
  const now = Date.now();
  const record = apiRateLimits.get(identifier);

  if (!record || now - record.windowStart > windowMs) {
    const freshRecord = { count: 1, windowStart: now };
    apiRateLimits.set(identifier, freshRecord);
    return {
      allowed: true,
      remaining: maxRequests - 1,
      resetMs: windowMs,
    };
  }

  if (record.count >= maxRequests) {
    const resetMs = Math.max(0, windowMs - (now - record.windowStart));
    return {
      allowed: false,
      remaining: 0,
      resetMs,
    };
  }

  record.count += 1;
  const resetMs = Math.max(0, windowMs - (now - record.windowStart));
  return {
    allowed: true,
    remaining: maxRequests - record.count,
    resetMs,
  };
};
