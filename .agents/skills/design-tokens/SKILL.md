---
name: design-tokens
description: Use the app's V15 theme tokens for Flutter colors, spacing, radii, sizes, and motion. Apply when changing mobile UI or reviewing a visual value.
---

# Design tokens

Read `.agents/flutter-profile.yaml` and `.agents/flutter-conventions.md`. The profile
schema is documented in [the Flutter profile reference](references/flutter-profile.md).
If either file is absent, inspect the current theme source; do not block on a generator.

In this repository, `app/lib/app/tema/tokens.dart` defines `AppTokens` and its
`BuildContext` extension. Use the existing API:

```dart
final tokens = context.tokens;

Container(
  padding: EdgeInsets.all(tokens.spacing.four),
  decoration: BoxDecoration(
    color: tokens.colors.superficie,
    borderRadius: BorderRadius.circular(tokens.radii.lg),
  ),
  child: Text('Exemplo', style: Theme.of(context).textTheme.bodyMedium),
)
```

The extension contains `colors`, `spacing`, `radii`, `sizes`, and `motion`. Typography
comes from `Theme.of(context).textTheme`; do not invent a `context.tokens.text` API.
For existing code that uses the older `Tokens` aliases, keep changes local unless the
task explicitly asks for migration.

## Applying a V15 design

Use `design-app/mobile-v15/index.html` as the visual source of truth and
`docs/guias/design-v15.md` as the token/component contract. Do not assume a Figma frame
or substitute generic Material defaults.

1. Identify the specified value in the relevant HTML state and design guide.
2. Reuse the matching token in `context.tokens`.
3. If the design specifies a value the token system cannot express, report the exact
   mismatch. Do not silently change the design or guess a replacement.
4. Keep light and dark mode values in the theme/token layer; widgets should resolve the
   active `context.tokens` at build time.

Use semantic color fields such as `tokens.colors.acao` or `tokens.colors.superficie`,
not the legacy aliases or raw `Color(...)` literals for new widget code. Use the existing
spacing, radius, size, and motion fields rather than adding one-off values. Adding or
changing a shared token is part of the visual system and must match the V15 contract.

The template at `references/theme-extension-template.dart` is for projects that lack a
token extension. This app already has one; do not copy the template into it.
