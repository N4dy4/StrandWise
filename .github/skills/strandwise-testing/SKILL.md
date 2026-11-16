---
name: strandwise-testing
description: Run, extend, and maintain StrandWise's automated tests, including the main-branch workflow that opens GitHub issues when tests fail.
---

# StrandWise Testing

Use this skill when adding tests, changing CI, or investigating failed test runs.

## Automation

- `.github/workflows/main-tests.yml` runs on every push to `main`: `flutter pub get`,
  `flutter analyze`, `flutter test`.
- If analyze or tests fail, the workflow opens a GitHub issue titled
  `Tests failed on main (<short sha>)` labeled `bug`, with step outcomes, the run
  link, and a log tail. A repeat failure for the same commit comments on the
  existing open issue instead of creating a duplicate.
- `.github/workflows/ci.yml` still covers pull requests and the debug APK build.
- The workflow needs only the default `GITHUB_TOKEN` (`issues: write`); never
  add personal tokens or secrets.

## Local commands

Run from `app/`:

```sh
flutter pub get
flutter analyze
flutter test
flutter test test/content_test.dart   # single file
```

## Testing priorities

- Unit-test pure logic first: routine engine, ingredient flagging, content ranking.
- Widget tests: onboarding quiz flow, wash calendar, reminder scheduling.
- Tests must run without Supabase configured (local mode) and must not call
  external APIs (Tavily, YouTube).
- Preserve citation behavior: items and products keep a non-empty `source_url`.

## When a test-failure issue appears

1. Reproduce locally with the commands above.
2. Fix on a branch named `issue-<number>-<slug>`; reference the issue in the PR.
3. Close the issue when `main` is green again.
