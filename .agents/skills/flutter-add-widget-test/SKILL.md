---
name: flutter-add-widget-test
description: Add or update a focused Flutter widget test for a user-visible behavior directly changed in this repository's Android/iOS app.
---

# Focused Flutter widget tests

Before editing, read the test beside the changed screen/component and the relevant part
of `AGENTS.md`. `flutter_test` is already in `app/pubspec.yaml`; use the existing setup,
test helpers, naming, and fixture style. Do not add a dependency or copy a generic test
application when the project already provides a suitable pump helper.

## Scope

- Change only unit/widget tests directly affected by the implementation.
- Keep tests under `app/test/`, mirroring the source location and existing naming.
- Assert user-visible state, action, and navigation behavior. Prefer the same app shell and
  navigator setup used by nearby tests when route behavior matters.
- For a secondary route with a previous route, cover both tapping the visible header back
  control and the Android system-back event, asserting return to the existing route and
  preserved state where applicable.
- Do not add integration, E2E, smoke, golden/visual-regression, performance, or Flutter
  Web tests. Do not run the full suite; run only the directly related test files.
- Keep the commented compact Shopping Inter widget test pending for the manual decision
  documented in `AGENTS.md`. Do not remove its comment or change its expectation.

Run an affected test from the Flutter package root, for example:

```sh
cd app
flutter test test/app/paginas/meu_radar_test.dart
```

Use the actual affected path. If widget-test coverage changes, update the applicable
entry in `docs/testes/TESTES.md` and the relevant product documentation as required by
`AGENTS.md`.
