# Copilot Instructions — StrandWise

## Commands

All Flutter commands run from `app/`:

```sh
flutter pub get                    # install deps
flutter analyze                    # lint (flutter_lints)
flutter test                       # all tests
flutter test test/widget_test.dart # single test file
flutter test --plain-name "Theme"  # single test by name
flutter build ios --no-codesign    # iOS build check
```

CI (`.github/workflows/ci.yml`) runs analyze + test + debug APK build on push/PR.

Secrets are never committed — Supabase keys go in via `--dart-define` (see `app/lib/config/supabase_config.dart` and `docs/SUPABASE_SETUP.md`).

## Architecture

`docs/PLAN.md` is the authoritative product spec — read it before architectural decisions and flag requests that contradict it.

- **Frontend:** Flutter in `app/` (iOS first, Android later — one codebase is the point)
- **Backend:** Supabase (managed Postgres + auth + photo storage). No custom API server unless the plan changes. The app must run without Supabase configured (local mode) — see the `SupabaseConfig.isConfigured` guard in `app/lib/main.dart`.
- **Content sources (Phase 2):** YouTube Data API for videos; Tavily or SerpAPI for articles/products
- **Personalization:** v1 is a **rule-based engine** (hair type × concerns → routine templates). Do not add ML dependencies or "AI-optimized" claims for v1 — ML is explicitly v2.

Code layout in `app/lib/`: `theme/` (design tokens), `config/` (build-time config). Features will be added per `docs/PLAN.md` phases.

## Hard product requirements (design constraints, not suggestions)

| Req | What it means in code |
|-----|----------------------|
| R1 | Pink, friendly, approachable UI. Use the tokens in `app/lib/theme/app_theme.dart` (`AppColors`, `AppTheme.cornerRadius`) instead of ad-hoc colors/radii. |
| R2 | Every piece of web-sourced content/product must carry a linked citation. Content rows are stored in Postgres **with `source_url`** so citations are permanent — never strip or omit it. Cite and link out; never re-host videos/articles (ToS risk). |
| R3 | Routine tracking and reminders must work **offline-first** — design local persistence accordingly, sync when connected. |
| R4 | Privacy by default: hair photos and profile data are never shared; Supabase tables get RLS enabled. Any hair/scalp advice (especially hair loss) needs a visible "not medical advice" disclaimer. |

## Data model (planned, Phase 1+)

Key tables: `users`, `hair_profiles`, `routines`, `routine_steps`, `ingredients`, `products`, `product_ingredients`, `content_items`, `progress_logs`, `reminders`.

## Testing priorities

- Routine-engine logic and ingredient flagging rules are **pure functions** — unit-test these first.
- Widget/integration tests: onboarding quiz flow, reminder scheduling.
