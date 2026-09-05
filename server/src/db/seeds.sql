-- ==============================================================================
-- Stoptify Initial Seed Data
-- File: seeds.sql
-- Description: Seeds a realistic roadmap with topics containing the 3-tier
--              Definition of Done and assessments.
-- ==============================================================================

-- 1. Insert Sample Roadmap
INSERT INTO roadmaps (id, title, slug, target_career, duration_weeks, difficulty_level, is_public)
VALUES (
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'Backend Engineering & Distributed Systems',
    'backend-mastery',
    'Backend Engineer / Cloud Architect',
    6,
    'Intermediate',
    TRUE
) ON CONFLICT (slug) DO NOTHING;

-- 2. Insert Topics with 3-Tier Definition of Done
-- Topic 1: HTTP Protocol & RESTful API Architecture
INSERT INTO topics (
    id, 
    roadmap_id, 
    title, 
    slug, 
    description, 
    order_index, 
    estimated_duration_min, 
    definition_of_done, 
    anti_scope, 
    prerequisites_ids
) VALUES (
    'b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'HTTP Protocol & RESTful API Architecture',
    'http-protocol-rest-api',
    'Master HTTP status codes, headers, and idempotent vs non-idempotent methods.',
    1,
    '30 min',
    '{
        "conceptual": "Explain the difference between idempotent and non-idempotent HTTP methods in plain English (e.g. GET/PUT vs POST).",
        "practical": "Build a minimal Express endpoint with request validation using proper status codes (200, 201, 400, 404).",
        "anti_scope": "Do not study HTTP/3, gRPC, or QUIC protocol internals at this stage."
    }'::jsonb,
    '["HTTP/3", "gRPC", "QUIC internals"]'::jsonb,
    '[]'::jsonb
) ON CONFLICT (roadmap_id, slug) DO NOTHING;

-- Topic 2: Relational Database Indexing & Query Plans
INSERT INTO topics (
    id, 
    roadmap_id, 
    title, 
    slug, 
    description, 
    order_index, 
    estimated_duration_min, 
    definition_of_done, 
    anti_scope, 
    prerequisites_ids
) VALUES (
    'c3d4e5f6-a1b2-4c5d-0e1f-2a3b4c5d6e7f',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'Relational Database Indexing & Query Plans',
    'database-indexing-query-plans',
    'Understand how B-trees speed up reads, how indexes impact write latency, and how to read EXPLAIN ANALYZE output.',
    2,
    '45 min',
    '{
        "conceptual": "Explain how B-tree index lookups work versus full table scans in under 2 minutes.",
        "practical": "Run an EXPLAIN ANALYZE query on a table of 10,000 rows to verify an index scan is triggered instead of a Seq Scan.",
        "anti_scope": "Do not write custom GiST or SP-GiST index implementations yet."
    }'::jsonb,
    '["GiST custom indexes", "SP-GiST", "BRIN deep internals"]'::jsonb,
    '["b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e"]'::jsonb
) ON CONFLICT (roadmap_id, slug) DO NOTHING;

-- Topic 3: Caching Strategies & Redis Fundamentals
INSERT INTO topics (
    id, 
    roadmap_id, 
    title, 
    slug, 
    description, 
    order_index, 
    estimated_duration_min, 
    definition_of_done, 
    anti_scope, 
    prerequisites_ids
) VALUES (
    'd4e5f6a1-b2c3-4d5e-1f2a-3b4c5d6e7f8a',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'Caching Strategies & Redis Fundamentals',
    'caching-strategies-redis',
    'Learn Cache-Aside vs Write-Through patterns and cache invalidation strategies.',
    3,
    '40 min',
    '{
        "conceptual": "Articulate Cache-Aside vs Write-Through caching patterns and their trade-offs.",
        "practical": "Implement a Redis caching layer around a slow database read with a 60-second TTL.",
        "anti_scope": "Avoid multi-region Redis Cluster sharding and cross-datacenter replication setups."
    }'::jsonb,
    '["Redis Cluster multi-region", "Raft consensus"]'::jsonb,
    '["c3d4e5f6-a1b2-4c5d-0e1f-2a3b4c5d6e7f"]'::jsonb
) ON CONFLICT (roadmap_id, slug) DO NOTHING;

-- 3. Insert Baseline Assessments for Topic 1 (HTTP & REST)
INSERT INTO assessments (
    id,
    topic_id,
    type,
    questions,
    grading_rubric,
    passing_score_threshold,
    time_limit_seconds
) VALUES (
    'e5f6a1b2-c3d4-4e5f-2a3b-4c5d6e7f8a9b',
    'b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e',
    'oral_exam',
    '[
        {
            "tier": "eli5_core",
            "question": "In plain English, what does it mean for an HTTP method to be idempotent? Give an example.",
            "duration_seconds": 30
        },
        {
            "tier": "tradeoff_edge_case",
            "question": "If PUT is idempotent and POST is not, why wouldn'\''t we use PUT for every data creation request?",
            "duration_seconds": 45
        },
        {
            "tier": "real_world_application",
            "question": "A user clicks the Pay Now button twice within 100ms. How would you design your API endpoint to avoid charging them twice?",
            "duration_seconds": 45
        }
    ]'::jsonb,
    '{
        "eli5_pass_criteria": "Mentions that repeating the request results in the exact same state without unintended side effects.",
        "tradeoff_pass_criteria": "Recognizes that PUT requires knowing or specifying the exact resource URI, whereas POST allows the server to generate resource identity.",
        "application_pass_criteria": "Suggests Idempotency Keys, unique transaction tokens, or database unique constraints."
    }'::jsonb,
    80,
    180
) ON CONFLICT DO NOTHING;

