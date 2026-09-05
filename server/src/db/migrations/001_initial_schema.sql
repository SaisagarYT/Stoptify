-- ==============================================================================
-- Stoptify Backend Database Schema
-- Migration: 001_initial_schema.sql
-- Description: Creates all 14 core tables, constraints, foreign keys, 
--              indexes, and Row Level Security (RLS) policies.
-- ==============================================================================

-- 1. EXTENSIONS
-- uuid-ossp allows PostgreSQL to automatically generate random UUID identifiers.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- vector extension allows storing vector embeddings for Pinecone/RAG semantic search.
CREATE EXTENSION IF NOT EXISTS "vector";

-- ==============================================================================
-- 2. USER & AUTHENTICATION TABLES
-- ==============================================================================

-- USERS: Stores authenticated learner accounts.
-- Why soft delete? "deleted_at" allows users to deactivate without breaking historical
-- audit logs or foreign keys in completed roadmaps.
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    encrypted_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    avatar_url VARCHAR(500),
    preferences JSONB DEFAULT '{"theme": "system", "daily_goal_minutes": 30, "notifications_enabled": true}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- USER_SKILLS: Tracks a user's verified skills & proficiency levels (1 = Beginner, 5 = Master).
CREATE TABLE IF NOT EXISTS user_skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    proficiency_level INT NOT NULL CHECK (proficiency_level BETWEEN 1 AND 5),
    assessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 3. ROADMAP & TOPIC CURRICULUM TABLES
-- ==============================================================================

-- ROADMAPS: The top-level learning path (e.g. "Backend Engineering", "DevOps").
-- "slug": Clean URL-friendly identifier for deep-linking (e.g. "backend-engineering").
CREATE TABLE IF NOT EXISTS roadmaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    target_career VARCHAR(150),
    duration_weeks INT DEFAULT 4,
    difficulty_level VARCHAR(50) DEFAULT 'Intermediate', -- Beginner, Intermediate, Advanced
    structure_template JSONB DEFAULT '{}'::jsonb,
    is_public BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- USER_ROADMAPS: Tracks a user's enrollment and overall completion rate in a roadmap.
CREATE TABLE IF NOT EXISTS user_roadmaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    roadmap_id UUID NOT NULL REFERENCES roadmaps(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'in_progress', -- 'not_started', 'in_progress', 'completed', 'paused'
    overall_progress_percent REAL DEFAULT 0.0 CHECK (overall_progress_percent BETWEEN 0.0 AND 100.0),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, roadmap_id)
);

-- TOPICS: Individual milestones inside a roadmap.
-- Holds the critical 3-tier "Definition of Done":
--   1. Conceptual (ELI5 articulation)
--   2. Practical (Hands-on task)
--   3. Anti-scope (What NOT to study yet to avoid overwhelm)
CREATE TABLE IF NOT EXISTS topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roadmap_id UUID NOT NULL REFERENCES roadmaps(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT,
    order_index INT NOT NULL DEFAULT 1,
    estimated_duration_min VARCHAR(50) DEFAULT '30 min',
    definition_of_done JSONB NOT NULL DEFAULT '{"conceptual": "", "practical": "", "anti_scope": ""}'::jsonb,
    anti_scope JSONB DEFAULT '[]'::jsonb,
    prerequisites_ids JSONB DEFAULT '[]'::jsonb, -- Array of topic UUIDs that must be passed first
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(roadmap_id, slug)
);

-- USER_TOPIC_PROGRESS: Tracks each student's progress through individual topics.
CREATE TABLE IF NOT EXISTS user_topic_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_roadmap_id UUID NOT NULL REFERENCES user_roadmaps(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'locked', -- 'locked', 'in_progress', 'completed'
    attempts_count INT DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_roadmap_id, topic_id)
);

-- ==============================================================================
-- 4. KNOWLEDGE BASE & RAG (RETRIEVAL-AUGMENTED GENERATION) TABLES
-- ==============================================================================

-- USER_UPLOADS: Stores metadata for documents uploaded by the user (notes, PDFs).
CREATE TABLE IF NOT EXISTS user_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(1000) NOT NULL,
    file_type VARCHAR(50),
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    storage_path VARCHAR(1000),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE
);

-- DOCUMENT_CHUNKS: Chunks extracted from uploaded files for semantic search.
-- Vector dimension 1536 corresponds to standard OpenAI / Gemini text-embedding models.
CREATE TABLE IF NOT EXISTS document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    upload_id UUID NOT NULL REFERENCES user_uploads(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    embedding vector(1536),
    chunk_index INT NOT NULL,
    source_page VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- GENERATED_CONTENT: Textbook chapters, summaries, and diagrams generated by AI for a topic.
CREATE TABLE IF NOT EXISTS generated_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL, -- 'textbook_chapter', 'cheat_sheet', 'mermaid_diagram'
    body TEXT NOT NULL,
    version VARCHAR(20) DEFAULT 'v1.0',
    metadata JSONB DEFAULT '{}'::jsonb,
    generated_by_ai_model VARCHAR(100), -- Model identifier (e.g. 'gemini-1.5-pro')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 5. MULTI-MODAL ASSESSMENT & FEYNMAN ORAL EXAM TABLES
-- ==============================================================================

-- ASSESSMENTS: Quizzes, drag-and-drop challenges, or oral defense prompts for a topic.
CREATE TABLE IF NOT EXISTS assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'oral_exam', 'mcq', 'drag_and_drop'
    questions JSONB NOT NULL,
    grading_rubric JSONB DEFAULT '{}'::jsonb,
    passing_score_threshold INT DEFAULT 80, -- Need >= 80% to pass
    time_limit_seconds INT DEFAULT 180,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- USER_ASSESSMENT_RESULTS: Records each assessment attempt and its grade.
CREATE TABLE IF NOT EXISTS user_assessment_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_topic_progress_id UUID NOT NULL REFERENCES user_topic_progress(id) ON DELETE CASCADE,
    assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
    score REAL NOT NULL CHECK (score BETWEEN 0.0 AND 100.0),
    feedback JSONB DEFAULT '{}'::jsonb,
    user_answers_snapshot JSONB DEFAULT '{}'::jsonb,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    passed BOOLEAN NOT NULL DEFAULT FALSE,
    ai_examiner_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ORAL_EXAM_SESSIONS: Detailed logs for Feynman oral defenses (audio + transcript + AI evaluation).
CREATE TABLE IF NOT EXISTS oral_exam_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_assessment_result_id UUID NOT NULL REFERENCES user_assessment_results(id) ON DELETE CASCADE,
    audio_recording_url VARCHAR(1000),
    transcript TEXT,
    ai_evaluation JSONB DEFAULT '{}'::jsonb,
    confidence_score REAL CHECK (confidence_score BETWEEN 0.0 AND 1.0),
    session_status VARCHAR(50) DEFAULT 'completed', -- 'in_progress', 'completed', 'failed'
    session_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 6. SYSTEM AUDIT & SECURITY TABLES
-- ==============================================================================

-- SYSTEM_AUDIT_LOGS: Audit trail for user actions (security, compliance, debugging).
CREATE TABLE IF NOT EXISTS system_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL, -- 'LOGIN', 'SUBMIT_ASSESSMENT', 'ENROLL_ROADMAP'
    payload JSONB DEFAULT '{}'::jsonb,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- API_RATE_LIMITS: Tracks request counters to protect against DDOS or AI API abuse.
CREATE TABLE IF NOT EXISTS api_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier VARCHAR(150) NOT NULL UNIQUE, -- IP address or User ID
    request_count INT DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 7. PERFORMANCE INDEXES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_user_skills_user_id ON user_skills(user_id);
CREATE INDEX IF NOT EXISTS idx_roadmaps_slug ON roadmaps(slug);
CREATE INDEX IF NOT EXISTS idx_topics_roadmap_id ON topics(roadmap_id);
CREATE INDEX IF NOT EXISTS idx_topics_order_index ON topics(roadmap_id, order_index);
CREATE INDEX IF NOT EXISTS idx_user_roadmaps_user_id ON user_roadmaps(user_id);
CREATE INDEX IF NOT EXISTS idx_user_topic_progress_roadmap ON user_topic_progress(user_roadmap_id);
CREATE INDEX IF NOT EXISTS idx_user_uploads_user_id ON user_uploads(user_id);
CREATE INDEX IF NOT EXISTS idx_assessments_topic_id ON assessments(topic_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON system_audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_rate_limits_identifier ON api_rate_limits(identifier);

-- ==============================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- Ensures each user can only read and write their own data in Supabase.
-- ==============================================================================

-- Enable RLS on private user tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roadmaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_topic_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_assessment_results ENABLE ROW LEVEL SECURITY;

-- Public can read published roadmaps and topics
ALTER TABLE roadmaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read-access for published roadmaps"
    ON roadmaps FOR SELECT
    USING (is_public = TRUE);

CREATE POLICY "Public read-access for topics of published roadmaps"
    ON topics FOR SELECT
    USING (EXISTS (SELECT 1 FROM roadmaps WHERE roadmaps.id = topics.roadmap_id AND roadmaps.is_public = TRUE));

