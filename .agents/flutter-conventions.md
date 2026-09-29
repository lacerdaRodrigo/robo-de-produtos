# Flutter conventions for Radar de Benefícios

This file records stable locations and project choices. Search the live source for
specific widgets and current behavior; do not treat this as an inventory.

## Scope and visual authority

- This repository's app target is Flutter for Android and iOS.
- For mobile UI, `design-app/mobile-v15/index.html` is the visual source of truth and
  `docs/guias/design-v15.md` defines the design contract. Follow both before changing a
  screen. Record an undefined design decision instead of inventing one.
- The Flutter app remains an API client. Do not add direct Flutter access to Neon,
  Livelo, or Inter.

## Source layout

- Flutter package root: `app/`.
- App shell, navigation, shared components, authentication, identity, and theme:
  `app/lib/app/`.
- Domain screens and state: `app/lib/features/<domain>/`.
- API and authentication infrastructure: `app/lib/core/`.
- Relevant unit and widget tests: `app/test/`, following the source directory and
  feature naming.
- Navigation uses Flutter `Navigator`; preserve the existing stack and route state.

## Visual system

- Shared V15 widgets and states: `app/lib/app/componentes/`, especially
  `fundacao_visual.dart` and `estados.dart`. Search these files and the active feature
  before adding another component.
- Theme construction: `app/lib/app/tema/tema.dart`.
- Theme extension and visual values: `app/lib/app/tema/tokens.dart`, exposed as
  `context.tokens`. It contains `colors`, `spacing`, `radii`, `sizes`, and `motion`;
  typography comes from `Theme.of(context).textTheme`.
- The app font is Manrope, declared in `app/pubspec.yaml`.
- Assets live under `app/assets/brand/`, `app/assets/illustrations/`, and
  `app/assets/fonts/`; their directories are declared in `app/pubspec.yaml`. Use the
  existing `flutter_svg` package for SVG assets.
- Existing screen previews live in `app/lib/app/previews/`; `v15.dart` is the current
  V15 preview entry point.

## Implementation choices

- State uses local `setState` and purpose-built `ChangeNotifier` controllers. Reuse the
  nearest existing pattern; do not add a state-management package for a screen task.
- Models are handwritten. Do not add a generator for a local UI change.
- User-facing copy is Brazilian Portuguese and currently has no app ARB/localization
  layer. Keep new labels and semantics in Portuguese; do not introduce a parallel
  localization package without a separate product decision.
- Prefer directional insets for new layout code and retain Android/iOS back behavior.
