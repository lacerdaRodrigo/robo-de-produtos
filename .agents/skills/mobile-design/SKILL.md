---
name: mobile-design
description: Implement or adjust this repository's Flutter Android/iOS UI against the approved mobile V15 reference. Use for screens, widgets, navigation, states, and responsive phone/tablet layout.
---

# Flutter mobile V15

The root `AGENTS.md` is the operating contract. Follow it before this skill whenever the
two differ. This repository's supported app journey is Flutter on Android/iOS.

## Before changing a screen

Read only the required sources:

1. `design-app/mobile-v15/index.html` for the visual structure, hierarchy, states, and
   navigation.
2. `docs/guias/design-v15.md` for colors, components, states, composition, and gates.
3. Flutter source and unit/widget tests directly related to the current screen.
4. `docs/README.md` and the relevant PRD only when a business rule, data, or API contract
   needs confirmation.

Do not browse other prototypes, desktop/web implementations, backend code, or broad
historical documentation by default. Do not infer production data from illustrative HTML.

## Implementation

- Reproduce the selected V15 state. Do not invent components, spacing, copy, colors,
  navigation, or visual treatments absent from the approved reference. Record a gap and
  ask for a decision when the sources do not specify the answer.
- Follow `.agents/flutter-conventions.md` and `.agents/flutter-profile.yaml`; use the
  existing widgets, `context.tokens`, theme, assets, and navigation stack.
- Keep Flutter as an API client. Preserve server-owned financial values, pagination,
  search state, filters, useful scroll position, and the distinction between failure,
  partial, delayed, missing, and zero values.
- A secondary route with a previous route has a visible accessible header back control.
  Use the existing `Navigator` stack; system back/gesture must return to that same route
  without resetting state or duplicating a page.
- Keep light/dark behavior and Android/iOS phone/tablet layouts consistent with what the
  V15 source defines. Do not add a desktop or Flutter Web target.

For code conventions, accessibility, tokens, and layout, apply the focused project skills:
`codebase-conventions`, `a11y-and-rtl`, `design-tokens`, and `responsive-adaptive`.

## Required completion gate

Follow the project cycle: implement, format, analyze, run only the directly affected
unit/widget tests, render and compare with the V15 HTML when needed, correct differences,
and repeat. `dart format` and `flutter analyze` are required. Do not add or run integration,
E2E, smoke, performance, automated visual regression, or Flutter Web tests.

Update the relevant PRD, test catalog, pending list, and document index when the changed
behavior makes those documents applicable. Report changed files, commands run, results,
and any unresolved visual or product decision.

## Supporting references

Load a reference only when its subject is needed. The other files under `references/`
contain generic multi-framework examples and do not override `AGENTS.md`, the V15 HTML,
or the project guide. In particular, skip their web, React Native, Compose, SwiftUI,
integration/E2E, golden, and broad manual-test workflows for this repository's V15 cycle.
