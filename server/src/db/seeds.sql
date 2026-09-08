-- Insert sample roadmap
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

-- Insert topic 1: HTTP and REST APIs
INSERT INTO topics (
    id, roadmap_id, title, slug, description, order_index, estimated_duration_min, definition_of_done, anti_scope, prerequisites_ids
) VALUES (
    'b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'HTTP Protocol & RESTful API Architecture',
    'http-protocol-rest-api',
    'Master HTTP status codes, headers, and idempotent vs non-idempotent methods.',
    1,
    '30 min',
    '{
        "conceptual": "Explain idempotent vs non-idempotent HTTP methods in plain English.",
        "practical": "Build an Express endpoint with validation using proper status codes.",
        "anti_scope": "Do not study HTTP/3, gRPC, or QUIC internals yet."
    }'::jsonb,
    '["HTTP/3", "gRPC", "QUIC internals"]'::jsonb,
    '[]'::jsonb
) ON CONFLICT (roadmap_id, slug) DO NOTHING;

-- Insert topic 2: Database Indexing
INSERT INTO topics (
    id, roadmap_id, title, slug, description, order_index, estimated_duration_min, definition_of_done, anti_scope, prerequisites_ids
) VALUES (
    'c3d4e5f6-a1b2-4c5d-0e1f-2a3b4c5d6e7f',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'Relational Database Indexing & Query Plans',
    'database-indexing-query-plans',
    'Understand B-tree indexes, write overhead, and EXPLAIN ANALYZE execution plans.',
    2,
    '45 min',
    '{
        "conceptual": "Explain B-tree index lookups vs full table scans in under 2 minutes.",
        "practical": "Run an EXPLAIN ANALYZE query to verify index scan vs sequence scan.",
        "anti_scope": "Do not write custom GiST or SP-GiST index implementations yet."
    }'::jsonb,
    '["GiST custom indexes", "SP-GiST"]'::jsonb,
    '["b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e"]'::jsonb
) ON CONFLICT (roadmap_id, slug) DO NOTHING;

-- Insert topic 3: Redis Caching
INSERT INTO topics (
    id, roadmap_id, title, slug, description, order_index, estimated_duration_min, definition_of_done, anti_scope, prerequisites_ids
) VALUES (
    'd4e5f6a1-b2c3-4d5e-1f2a-3b4c5d6e7f8a',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'Caching Strategies & Redis Fundamentals',
    'caching-strategies-redis',
    'Learn Cache-Aside and Write-Through caching patterns with TTL expiry.',
    3,
    '40 min',
    '{
        "conceptual": "Articulate Cache-Aside vs Write-Through caching patterns and trade-offs.",
        "practical": "Implement a Redis caching layer around a database query with TTL.",
        "anti_scope": "Avoid multi-region Redis Cluster sharding at this stage."
    }'::jsonb,
    '["Redis Cluster multi-region", "Raft consensus"]'::jsonb,
    '["c3d4e5f6-a1b2-4c5d-0e1f-2a3b4c5d6e7f"]'::jsonb
) ON CONFLICT (roadmap_id, slug) DO NOTHING;

-- Insert sample assessment for topic 1
INSERT INTO assessments (
    id, topic_id, type, questions, grading_rubric, passing_score_threshold, time_limit_seconds
) VALUES (
    'e5f6a1b2-c3d4-4e5f-2a3b-4c5d6e7f8a9b',
    'b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e',
    'oral_exam',
    '[
        {
            "tier": "eli5_core",
            "question": "What does it mean for an HTTP method to be idempotent? Give an example.",
            "duration_seconds": 30
        },
        {
            "tier": "tradeoff_edge_case",
            "question": "If PUT is idempotent and POST is not, why not use PUT for every request?",
            "duration_seconds": 45
        },
        {
            "tier": "real_world_application",
            "question": "A user clicks Pay Now twice within 100ms. How do you prevent double charging?",
            "duration_seconds": 45
        }
    ]'::jsonb,
    '{
        "eli5_pass_criteria": "Mentions that repeating the request results in identical state without side effects.",
        "tradeoff_pass_criteria": "Notes that PUT requires client knowing resource URI, POST lets server create URI.",
        "application_pass_criteria": "Suggests Idempotency Keys or database unique transaction constraints."
    }'::jsonb,
    80,
    180
) ON CONFLICT DO NOTHING;

-- Insert sample MCQ assessment for topic 1
INSERT INTO assessments (
    id, topic_id, type, questions, grading_rubric, passing_score_threshold, time_limit_seconds
) VALUES (
    'f6a1b2c3-d4e5-4f6a-3b4c-5d6e7f8a9b0c',
    'b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e',
    'mcq',
    '[
        {
            "id": "q1",
            "prompt": "Which of the following HTTP methods is considered idempotent by specification?",
            "options": ["POST", "PATCH", "PUT", "CONNECT"],
            "correct_index": 2,
            "explanation": "PUT is idempotent because multiple identical requests have the exact same server state as a single request."
        },
        {
            "id": "q2",
            "prompt": "Which status code should be returned when a resource is successfully created?",
            "options": ["200 OK", "201 Created", "204 No Content", "202 Accepted"],
            "correct_index": 1,
            "explanation": "201 Created signals that the request succeeded and a new resource was created."
        }
    ]'::jsonb,
    '{}'::jsonb,
    80,
    120
) ON CONFLICT DO NOTHING;

-- Insert sample AI-generated textbook chapter
INSERT INTO generated_content (
    id, topic_id, content_type, body, version, metadata, generated_by_ai_model
) VALUES (
    '7a8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d',
    'b2c3d4e5-f6a1-4b5c-9d0e-1f2a3b4c5d6e',
    'textbook_chapter',
    '# HTTP Protocol & REST Architecture

HTTP defines how clients and servers exchange data. Safe methods do not mutate state (GET). Idempotent methods can be repeated safely (PUT, DELETE). Non-idempotent operations (POST) create new resources on each invocation.',
    'v1.0',
    '{"readingTimeMinutes": 5}'::jsonb,
    'gemini-1.5-pro'
) ON CONFLICT DO NOTHING;
