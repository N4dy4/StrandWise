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
