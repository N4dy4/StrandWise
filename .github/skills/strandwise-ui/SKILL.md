# StrandWise UI

Use this skill for Flutter UI work in StrandWise. The runnable app is in
`app/`; do not recreate or edit a separate Figma/React implementation.

## Design system

Use `app/lib/theme/app_theme.dart` as the single source of design tokens:

- Background: `AppColors.blush`
- Card surface: `AppColors.cream`
- Text: `AppColors.ink`; secondary text: `AppColors.muted`
- Primary accent: `AppColors.pink`; soft accent: `AppColors.rose`
- Emphasis: `AppColors.deepPink`; borders: `AppColors.border`
- Use `AppTheme.cornerRadius` for standard controls and 24 px rounded cards.

The visual direction is warm, pink, friendly, and editorial:

- Fraunces is used for display and headline typography through `AppTheme`.
- Inter is used for body text through `AppTheme`.
- Use generous spacing, white rounded cards, pill-shaped primary buttons, and
  restrained pink accents.
- Use `StrandWiseLogo` from `app/lib/widgets/strandwise_logo.dart` for the
  brand mark. Its image asset is `app/assets/images/logo.png`.

## Screen patterns

- **Welcome:** centered logo, editorial headline, short supportive copy, and a
  full-width “Get started” action.
- **Disclaimer:** show the not-medical-advice notice before onboarding and
  require acknowledgement before continuing.
- **Onboarding:** show progress, a direct question, privacy-focused supporting
  text, selectable chips, and a bottom-aligned primary action.
- **Routine:** lead with the user’s hair type and an accent routine summary,
  then render each routine step as a rounded white card.
- **Learning/content:** show source attribution on every card and retain the
  external source action. Do not remove `source_url` handling.
- **Search:** put the answer summary above linked source cards and repeat the
  visible not-medical-advice notice.
- **Ingredients:** use a clear match score and compact ingredient suitability
  rows; preserve the linked source for web-sourced products.
- **Progress, offline, and privacy:** keep progress photos device-local,
  explain offline behavior, and surface privacy guarantees in the profile area.

## Product constraints

- Preserve the rule-based v1 personalization engine. Do not claim or imply
  machine-learning optimization.
- Routine tracking and reminders must remain offline-first.
- Hair/scalp advice, especially hair loss, requires a visible not-medical-
  advice disclaimer.
- Privacy UI must not imply that photos or profile information are shared.
- Reuse existing Flutter widgets and tokens instead of ad-hoc colors, radii,
  or duplicate design helpers.

## Verification

Run UI validation from `app/`:

```sh
flutter analyze
flutter test
```
