# Changelog (AI-assisted changes)

Newest first. Log every change made by an AI assistant here.

## 2026-10-27 — Competition plan: quiz, profile, routines
- Added onboarding quiz (`features/onboarding`), `HairProfile` fields (porosity, density, scalp) with JSON, and local `ProfileStore` (shared_preferences, offline-first).
- Added rule-based `RoutineEngine` + `RoutineScreen`; home screen now routes quiz -> routine -> Discover using the saved profile (placeholder `3B` removed).
- Added `test/routine_test.dart`.

## 2026-10-27 — Phase 2: content source APIs
- Added `supabase/functions/sync-content` Edge Function: fetches videos (YouTube Data API) and articles (Tavily) into `content_items` with `source_url`. Untested/undeployed.
- Added migration `0004_content_source_url_unique.sql` (unique `source_url` for upserts).
- Documented key setup, deploy, and sync in `docs/SUPABASE_SETUP.md` (section 6).

## 2026-10-27 — Phase 2: public catalog reads + seed data
- `0002_content_and_products.sql`: read policies now allow `anon` as well as `authenticated` (catalog data only).
- Added `0003_seed_content.sql` with sample content, ingredients, and products.

## 2026-10-27 — Phase 2: content feed and product search
- Added models (`HairProfile`, `ContentItem`, `Product`), `ContentRanker`, `IngredientFlagger` (pure, rule-based).
- Added `ContentRepository` (Supabase or local sample data), `ContentHubScreen` (feed + product search with citations and disclaimers), and a "Discover" button on the home screen using a placeholder `3B` profile.
- Added migration `0002_content_and_products.sql` (RLS enabled), `url_launcher` dependency, and `test/content_test.dart`.
