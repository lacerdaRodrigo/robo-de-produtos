---
name: flutter-build-responsive-layout
description: Build or adjust a Flutter layout that adapts to the available Android/iOS phone or tablet window while following the V15 design.
---

# Build a responsive Flutter layout

Use [the project responsive-layout rules](../responsive-adaptive/SKILL.md) together with
the relevant mobile V15 HTML state and `docs/guias/design-v15.md`.

Start from the parent constraints, not from a guessed device category. Use `LayoutBuilder`
for component decisions and `MediaQuery.sizeOf(context)` for screen-shell decisions.
Preserve the V15 hierarchy and component behavior while allowing text and content to
reflow within supported Android/iOS sizes. Do not create a desktop/Web layout or hardcode
the reference artboard as a target size.

Before choosing a breakpoint or fixed dimension, search the existing shell and
`context.tokens`; reuse the established value when it matches the V15 behavior. If the
approved design does not define the needed behavior, record the gap rather than guessing.

Run `dart format`, `flutter analyze`, and only the directly affected unit/widget tests
required by `AGENTS.md`. Include the affected width cases in those tests when they are
part of the changed behavior.
