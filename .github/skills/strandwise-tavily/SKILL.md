---
name: strandwise-tavily
description: Implement and maintain Tavily-backed StrandWise article and product content ingestion with permanent source citations.
---

# StrandWise Tavily Content

Use this skill when implementing, reviewing, or troubleshooting Tavily content
search and ingestion for StrandWise.

## Integration boundary

- Tavily supplies external articles and product information in Phase 2. Use the
  Supabase Edge Function in `supabase/functions/sync-content/index.ts`; do not
  add a custom API server.
- Keep `TAVILY_API_KEY` in Supabase secrets. Never put it in Flutter source,
  configuration files, or committed documentation.
- The sync function authenticates requests with `SYNC_SECRET`; preserve that
  check when changing the endpoint.
- The Flutter app must continue to run without Supabase configured.

## Content requirements

- Every Tavily result stored in `content_items` must retain its original
  `source_url`, title, and source name.
- Deduplicate and upsert content by `source_url`; do not strip query URLs or
  replace the original external link.
- Render source attribution and an external-link action in the app. Link out;
  never re-host articles, videos, or other source content.
- Preserve hair type and concern metadata so content remains relevant to the
  user profile.
- Hair and scalp content, especially hair-loss information, must retain a
  visible not-medical-advice disclaimer in the UI.

## Verification

For Flutter changes, run from `app/`:

```sh
flutter analyze
flutter test
```
