# Stoptify — Flutter Scaffold

Mastery-based learning platform. Dark-mode-first, "Deep Obsidian & Cyber-Academic"
design system, generative-UI roadmap dashboard, and a full 6-screen flow wired to
the backend API contract in the master spec.

## Getting started

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:5050
```

`API_BASE_URL` defaults to `http://localhost:5050` (matching the spec) if omitted.

If you use `freezed`/`json_serializable` codegen later, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project map

```
lib/
  core/
    theme/          Design system: app_colors.dart, app_typography.dart, app_theme.dart
    network/         Dio client + JWT interceptor (api_client.dart), token_storage.dart
    router/           go_router config + auth redirect guard (app_router.dart), route_paths.dart
    constants/        api_endpoints.dart — every backend route from the spec
  models/            Plain Dart models mirroring each endpoint's response shape
  providers/         Riverpod StateNotifiers / FutureProviders per feature
  widgets/
    common/           GlassCard, GradientButton, StatusPill, PulsingRing
    roadmap/          TopicCard (the big generative-UI card), VelocityBanner
  screens/
    auth/                     Screen 1 — Login, Register, Skill Baseline
    resume_intake/            Screen 2 — Resume upload + Domain Category Selector
    consultation/             Screen 3 — Diagnostic Consultation Studio (chat)
    roadmap_dashboard/        Screen 4 — Generative UI Roadmap Dashboard
    textbook_reader/          Screen 5 — AI Textbook & Interactive Lab Reader
    assessment/               Screen 6 — Multi-Modal Assessment HUD
```

## What's implemented vs. stubbed

**Fully wired to the API contract:**
- Auth (register/login/me), JWT persistence via `flutter_secure_storage`, auto-injected
  `Authorization: Bearer` header on every request.
- Skill baseline submission, resume analysis, consultation chat + finalize,
  roadmap fetch/enroll/progress, RAG chapter generation, oral/MCQ/ordering assessment
  submission — all call the real endpoints from the spec's table.
- Router redirects unauthenticated users to `/login` and authenticated users away
  from `/login` and `/register` automatically, reacting live to auth state.

**Stubbed for you to flesh out next:**
- Oral defense speech capture — currently a placeholder transcript string;
  swap in `speech_to_text` (or your platform's mic pipeline) inside
  `_OralDefenseTabState._nextProbe()`.
- MCQ / sequence-ordering tabs currently seed local placeholder data — wire them to
  `GET /api/assessments/topic/:topicId` (see `topicAssessmentsProvider`) once that
  endpoint returns typed question payloads.
- Mermaid diagram rendering shows the raw diagram source in a code block; swap in
  a WebView + mermaid.js bridge (or a native Mermaid renderer package) inside
  `TextbookReaderScreen`.
- Confetti celebration animation on the ≥80% pass state — add a package like
  `confetti` and trigger it in `_ScoreGauge` / the MCQ and ordering submit handlers.

## Design tokens quick reference

| Token | Hex |
|---|---|
| Background | `#0A0E17` |
| Surface (glass) | `#121826` |
| Primary Indigo | `#6366F1` |
| Cyan Glow | `#06B6D4` |
| Mastery Verified | `#10B981` |
| Anti-Scope Amber | `#F59E0B` |
| Error Coral | `#F43F5E` |

Fonts: Plus Jakarta Sans (headings/badges), Inter (body), JetBrains Mono (code) —
all pulled at runtime via `google_fonts`, no bundled font assets needed.
