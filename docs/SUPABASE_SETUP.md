# Supabase Setup (Phase 0)

StrandWise uses Supabase for Postgres, auth, and progress-photo storage (see `docs/PLAN.md`). One-time provisioning:

## 1. Create the project

1. Go to https://supabase.com/dashboard and create a new project (e.g. `strandwise`).
2. Choose a region close to your beta users and save the database password somewhere safe.

## 2. Get the app credentials

In **Project Settings → API**, copy:

- **Project URL** (`https://<project-ref>.supabase.co`)
- **publishable key** (`sb_publishable_...`, the modern name for the anon key)

These are safe to ship in the client app — row-level security (RLS) protects the data. Never commit the `service_role` key.

## 3. Configure the app

Keys are injected at build time via `--dart-define` so nothing secret enters the repo:

```sh
cd app
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Without these flags the app still runs locally (Supabase features disabled).

For CI, add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as GitHub Actions secrets when integration tests need them.

## 4. Enable auth

In **Authentication → Providers**, enable **Email** (and Apple Sign-In later for iOS/TestFlight). Phase 0 exit criteria only require email sign-up/sign-in to work.

## 5. Schema

Phase 0 needs no tables yet. Phase 1 introduces `users` / `hair_profiles` etc. — see the table list in `docs/PLAN.md`. Create tables with RLS enabled by default (requirement R4: privacy by default).

## 6. Content APIs (Phase 2)

`supabase/functions/sync-content` pulls videos (YouTube Data API; TikTok via Tavily
search restricted to tiktok.com, `/@user/video/<id>` URLs only, oEmbed title/thumbnail
best effort), articles, and
official brand products (Tavily) with permanent `source_url` citations. Product
sync includes Camille Rose, SheaMoisture (types 1-4), Ecoslay, and The Doux, and
extracts each page's ingredient list when one can be parsed (so products can be
flagged); pages whose ingredients can't be parsed are saved without them.
Keys live in Supabase secrets, never in the app or repo.

1. Run migrations through `0012_content_source_url_unique.sql` (0011 adds `platform`, `thumbnail_url`, `published_at`; 0012 makes `source_url` unique for upserts) in the SQL Editor.
2. Get keys: YouTube Data API v3 (Google Cloud Console) and Tavily (https://tavily.com). Either one works alone.
3. Set secrets and deploy (needs the Supabase CLI, `brew install supabase/tap/supabase`):
   ```sh
   supabase secrets set YOUTUBE_API_KEY=... TAVILY_API_KEY=... SYNC_SECRET=<random string>
   supabase functions deploy sync-content --no-verify-jwt
   ```
4. Run a sync (repeat monthly; also re-validates the feed):
   ```sh
   curl -X POST https://<project-ref>.supabase.co/functions/v1/sync-content \
     -H "x-sync-secret: <SYNC_SECRET>" -H "Content-Type: application/json" \
   ```

**Hairstyle tutorials** (`hairstyle_tutorials`, migration 0013): a tutorials-only run,
enabled with `"includeTutorials": true` (add `"includeContent": true` to also run the
content sync). It searches YouTube for `<style> tutorial for <wavy|curly|coily> hair`
per style × curl family (medium-length videos, strict SafeSearch, English), keeps the top 3,
and upserts on `source_url`. Each search costs 100 quota units (default 10,000/day), so a
run is capped at 60 searches; process styles in batches:

```sh
curl -X POST https://<project-ref>.supabase.co/functions/v1/sync-content \
  -H "x-sync-secret: <SYNC_SECRET>" -H "Content-Type: application/json" \
  -d '{"includeTutorials":true,"styleOffset":0,"styleLimit":12}'
```

The response reports `searches`, `totalStyles` and `stoppedEarly` (quota/limit hit); continue with the next `styleOffset`.

## 7. AI assistant (Ask anything + hairstyles)

`supabase/functions/ask-hair-ai` calls a small hosted LLM for the Ask anything
tab and "Personalize with AI" on the Hairstyles tab. It uses Groq's free tier
(`openai/gpt-oss-20b`) through an OpenAI-compatible API; no card needed. The
key stays in Supabase secrets. Product picks are validated against the
`products` table so each carries its `source_url`. Without Supabase or the key,
the app falls back to rule-based hairstyles and shows a notice in Ask anything.

```sh
# free key: https://console.groq.com/keys
supabase secrets set AI_API_KEY=...
supabase functions deploy ask-hair-ai   # JWT verification on: the app's anon key is enough
```

Optional: `AI_MODEL` and `AI_BASE_URL` switch to any OpenAI-compatible provider
(e.g. Gemini free tier at `https://generativelanguage.googleapis.com/v1beta/openai`).
Free tiers are rate-limited; the app shows a retry message when it's hit.
