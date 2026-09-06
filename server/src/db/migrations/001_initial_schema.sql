-- Enable UUID and Vector extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- User accounts
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    encrypted_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    avatar_url VARCHAR(500),
    preferences JSONB DEFAULT '{"theme": "system", "daily_goal_minutes": 30}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- User skill proficiencies
CREATE TABLE IF NOT EXISTS user_skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    proficiency_level INT NOT NULL CHECK (proficiency_level BETWEEN 1 AND 5),
    assessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Learning roadmaps
CREATE TABLE IF NOT EXISTS roadmaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    target_career VARCHAR(150),
    duration_weeks INT DEFAULT 4,
    difficulty_level VARCHAR(50) DEFAULT 'Intermediate',
    structure_template JSONB DEFAULT '{}'::jsonb,
    is_public BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User enrollments in roadmaps
CREATE TABLE IF NOT EXISTS user_roadmaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    roadmap_id UUID NOT NULL REFERENCES roadmaps(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'in_progress',
    overall_progress_percent REAL DEFAULT 0.0 CHECK (overall_progress_percent BETWEEN 0.0 AND 100.0),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, roadmap_id)
);

-- Topics and milestones inside a roadmap
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
    prerequisites_ids JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(roadmap_id, slug)
);

-- User progress on individual topics
CREATE TABLE IF NOT EXISTS user_topic_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_roadmap_id UUID NOT NULL REFERENCES user_roadmaps(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'locked',
    attempts_count INT DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_roadmap_id, topic_id)
);

-- User document uploads for RAG
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

-- Document chunks and vector embeddings
CREATE TABLE IF NOT EXISTS document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    upload_id UUID NOT NULL REFERENCES user_uploads(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    embedding vector(1536),
    chunk_index INT NOT NULL,
    source_page VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI generated content for topics
CREATE TABLE IF NOT EXISTS generated_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL,
    body TEXT NOT NULL,
    version VARCHAR(20) DEFAULT 'v1.0',
    metadata JSONB DEFAULT '{}'::jsonb,
    generated_by_ai_model VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Topic assessments
CREATE TABLE IF NOT EXISTS assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    questions JSONB NOT NULL,
    grading_rubric JSONB DEFAULT '{}'::jsonb,
    passing_score_threshold INT DEFAULT 80,
    time_limit_seconds INT DEFAULT 180,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Assessment results and scores
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

-- Oral exam recordings and AI evaluations
CREATE TABLE IF NOT EXISTS oral_exam_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_assessment_result_id UUID NOT NULL REFERENCES user_assessment_results(id) ON DELETE CASCADE,
    audio_recording_url VARCHAR(1000),
    transcript TEXT,
    ai_evaluation JSONB DEFAULT '{}'::jsonb,
    confidence_score REAL CHECK (confidence_score BETWEEN 0.0 AND 1.0),
    session_status VARCHAR(50) DEFAULT 'completed',
    session_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- System audit trail
CREATE TABLE IF NOT EXISTS system_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL,
    payload JSONB DEFAULT '{}'::jsonb,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Rate limits per IP or user
CREATE TABLE IF NOT EXISTS api_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier VARCHAR(150) NOT NULL UNIQUE,
    request_count INT DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
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

-- Row Level Security policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roadmaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_topic_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_assessment_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE roadmaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

-- Allow public read access to roadmaps and topics
CREATE POLICY "Public read-access for published roadmaps"
    ON roadmaps FOR SELECT
    USING (is_public = TRUE);

CREATE POLICY "Public read-access for topics of published roadmaps"
    ON topics FOR SELECT
    USING (EXISTS (SELECT 1 FROM roadmaps WHERE roadmaps.id = topics.roadmap_id AND roadmaps.is_public = TRUE));
