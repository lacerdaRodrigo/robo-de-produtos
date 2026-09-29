---
name: a11y-and-rtl
description: Apply accessibility and direction-aware layout checks to Flutter UI, including semantics, readable text scaling, touch targets, contrast, and RTL when the app supports an RTL locale.
---

# Accessibility and directionality

Read `.agents/flutter-profile.yaml` for the app's current localization setup. Its field
definitions are in [the Flutter profile reference](../design-tokens/references/flutter-profile.md).
If the profile is absent, inspect the app's locale setup and continue; do not block on a
missing profile or a generator skill.

For this repository, preserve the V15 HTML and `docs/guias/design-v15.md` as the visual
contract. If a required accessibility adjustment would change a specified visual value,
record the conflict instead of silently changing the design.

## Apply to the changed widget

- Give icon-only controls a meaningful Brazilian Portuguese tooltip or semantic label.
- Keep decorative images out of the semantics tree. Group a price and its currency when
  that improves how the complete value is read.
- Respect the platform text scaler. Avoid fixed-height text containers and clipping that
  hides essential labels, errors, or values.
- Keep interactive controls at least 48 logical pixels where the design permits it; use
  the existing `context.tokens.sizes.touchTarget` token. Report a conflict with V15 for
  a decision instead of shrinking or expanding a control silently.
- Check text contrast against the actual theme surface (4.5:1 for normal text, 3:1 for
  large text). If a specified V15 combination misses the target, report the exact pair
  and ask for a design decision rather than changing its color unilaterally.
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, and directional positioning for
  new layout code when the direction is semantic. Follow established code when editing
  unrelated layout.
- Preserve Android system back and the visible V15 back control on secondary routes.

The current shipped locale is `pt-BR`, so RTL is not a release gate for ordinary changes.
Keep new code direction-aware; mirror navigation arrows and chevrons, but not logos or
play/check icons, when RTL is in scope. Add RTL-specific checks only when an RTL locale or
request is in scope.

## Verification

Add or update only a directly affected widget test when accessibility behavior changes.
Use the relevant unit/widget test file allowed by the project instructions. Do not add
golden, integration, E2E, or broad accessibility test suites as part of the V15 cycle.
