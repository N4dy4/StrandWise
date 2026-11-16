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

### Run with Supabase automatically

Put your credentials in the gitignored `.env` at the repo root (see `.env.example`):

```sh
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Then add this one line to `~/.zshrc` (use your actual repo path) and open a new terminal:

```sh
source "/path/to/hair app/scripts/flutter-supabase.sh"
```

From then on, `flutter run` anywhere inside this repo automatically adds the
`--dart-define` flags from `.env`; extra arguments (e.g. `-d chrome`) still work.
If the keys are missing it falls back to local mode with a warning. Other
`flutter` commands and other projects are unaffected.

## Checks

```sh
cd app
flutter analyze   # lint
flutter test      # unit + widget tests
```

CI runs analyze, test, and a debug APK build on every push/PR (`.github/workflows/ci.yml`).
