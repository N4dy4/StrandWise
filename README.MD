# StrandWise

A hair care companion app that builds personalized routines, educates users with cited sources, and helps them understand ingredients. See [docs/PLAN.md](docs/PLAN.md) for the full product plan.

## Structure

- `app/` — Flutter app (iOS first, Android later)
- `docs/` — product plan and setup guides

## Getting started

Requires the Flutter SDK (stable channel).

```sh
cd app
flutter pub get
flutter run
```

To enable backend features, pass Supabase credentials (see [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)):

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

## Checks

```sh
cd app
flutter analyze   # lint
flutter test      # unit + widget tests
```

CI runs analyze, test, and a debug APK build on every push/PR (`.github/workflows/ci.yml`).
