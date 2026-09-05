# Stoptify 🎯

> **A Mastery-Driven AI Learning Platform**  
> Moving learners away from passive video consumption ("tutorial hell") to demonstrable competence through active verification and Feynman-style oral defense.

---

## 📌 Architecture Overview

Stoptify couples an adaptive mobile client with a resilient backend orchestration pipeline and dual-database architecture:

- **Frontend**: Flutter (Dart) — Cross-platform, Material 3 design, Riverpod state management.
- **Backend Orchestrator**: Node.js & Express (ES Modules) — RESTful API, validation pipelines, WebSocket probe streaming.
- **Relational Storage & Auth**: Supabase / PostgreSQL with Row-Level Security (RLS) policies.
- **Vector Knowledge Base**: Pinecone & pgvector for Retrieval-Augmented Generation (RAG).

---

## 🏛️ Database & Domain Entities

The backend data layer is built around 14 relational entities:

1. `users` — Learner profiles, preferences, and authentication metadata.
2. `user_skills` — Verified skills and proficiency level assessments (1–5).
3. `roadmaps` — Structured curricula (e.g., Backend Engineering, System Design).
4. `user_roadmaps` — User enrollment, last accessed timestamps, and progress percentages.
5. `topics` — Step-by-step milestones enforced by a **3-Tier Definition of Done**:
   - **Conceptual**: Explain the core concept in plain English (ELI5).
   - **Practical**: Hands-on code or query implementation.
   - **Anti-Scope**: Explicit boundaries defining what *not* to study yet.
6. `user_topic_progress` — State tracking per topic (`locked`, `in_progress`, `completed`).
7. `user_uploads` — Learner-uploaded notes and documentation.
8. `document_chunks` — Ingested and embedded text chunks for semantic RAG search.
9. `generated_content` — Dynamic textbooks and Mermaid.js architecture diagrams.
10. `assessments` — Multi-modal tests (MCQ, interactive sandboxes, oral defenses).
11. `user_assessment_results` — Scores, snapshots of answers, and evaluation rubrics.
12. `oral_exam_sessions` — Transcripts, audio recording URLs, and Feynman probe evaluations.
13. `system_audit_logs` — Security tracking and immutable event audit trails.
14. `api_rate_limits` — Sliding-window abuse prevention for sensitive AI endpoints.

---

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+)
- Git

### Backend Setup
```bash
cd server
npm install
cp .env.example .env
npm run dev
```

The server starts by default on `http://localhost:5050`.

---

## 🗺️ Roadmap & Milestones
- [x] **Milestone 1**: Database Architecture & SQL Schema (DDL, Foreign Keys, RLS, Seeds)
- [ ] **Milestone 2**: Server Foundation & Clean Layered Architecture
- [ ] **Milestone 3**: Authentication & User Profiles
- [ ] **Milestone 4**: Roadmap & Topic Curriculum Engine
- [ ] **Milestone 5**: Multi-Modal Assessment & Feynman Oral Defense Engine
- [ ] **Milestone 6**: Document Processing & RAG Pipeline
- [ ] **Milestone 7**: Auditing, Rate Limiting & Integration Testing
- [ ] **Milestone 8**: Flutter Mobile Application
