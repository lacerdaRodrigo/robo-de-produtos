---
name: codebase-conventions
description: "Match existing Flutter conventions before adding or changing a widget, screen, shared component, text style, or asset reference in this repository."
---

# Codebase Conventions

The most common defect in agent-written Flutter is not a bug. It is a second
`PrimaryButton` — correct, tested, and redundant, because the project already had one
called `AppButton` and nothing looked for it.

Nothing in review catches this. The diff is all additions, every line is defensible, and
the duplication only surfaces months later when a brand change has to be applied twice.

> **Read the conventions file first.** `.agents/flutter-conventions.md` records where this
> project keeps its shared widgets, typography, colours, and assets, and what its naming
> rules are. The stack choices are in `.agents/flutter-profile.yaml`; its schema is in
> `.agents/skills/design-tokens/references/flutter-profile.md`. If the conventions file is
> absent, discover the source inline. There is no `flutter-adapt` skill dependency in
> this repository.
>
> If either file is absent, do the discovery below inline. A missing file is not a blocker.
>
> It records locations and rules, never an inventory of components. A list of every widget
> in the project is out of date within a week and then actively misleads. Search live; use
> the file to know where to search.

## Reuse before create

Search first, and search by **role**, not by the name you have in mind. Searching for
`PrimaryButton`, finding nothing, and building one is the failure — the project calls it
`AppButton`, and one grep for the wrong string is what convinced you otherwise.

For a component that renders X, search in this order:

1. **By suffix.** Search with `rg` for widget classes ending in `Button` under the Flutter
   source root. Do the same for `Card`, `Field`, `Tile`, `Sheet`, `Dialog`, `Chip`, and
   `Avatar`.
2. **By the noun in the request.** A "balance card" means searching `Balance` and `Card`
   separately, not `BalanceCard`.
3. **In the shared directories** the conventions file names, then in the current feature's
   `widgets/` directory.

Then read what you found before deciding. A widget that does 80% of what you need is
usually a parameter away from doing 100%, and adding the parameter is a smaller change
than adding a file.

**Report what you found and what you decided.** "Found `AppButton`, it has no loading
state, adding an `isLoading` parameter" is a reviewable decision. Silently creating
`LoadingButton` is not.

### When a new component is the right answer

- Nothing found after searching all three ways.
- What exists is genuinely a different thing — a `FilterChip` is not a `Tag` because they
  happen to be capsule-shaped.
- Extending the existing one would need a boolean that changes what it fundamentally is.
  Three or more independent boolean parameters usually means two widgets wearing a coat.

Do not create a new component because the existing one is in an inconvenient directory,
because its API is slightly awkward, or because it is easier to write a fresh one than to
read an existing one. Those are the three reasons duplication actually happens.

## Typography

Text styles come from the project's typography source. In this app, use
`Theme.of(context).textTheme` and `app/lib/app/tema/tema.dart`; custom spacing, color,
radius, size, and motion values come from `context.tokens` in
`app/lib/app/tema/tokens.dart`. `AppTokens` does not contain a text-style group.

For other projects, use the typography source named by their conventions file and profile.

If the design calls for a style the project does not have, add it to the typography source
and use it from there. Do not inline it "just this once" — the token that does not exist
yet is the whole reason the next person inlines one too.

Applying a single modifier to an existing style is fine and is not an inline style:

```dart
style: Theme.of(context).textTheme.bodyMedium
```

Reaching for `copyWith` on three properties at once means the style itself is missing.

## Assets

**Never invent an asset path.** A path that does not resolve throws at runtime, in the
widget, on the device — `flutter analyze` says nothing, tests that do not render that
screen say nothing, and it reaches a reviewer looking like working code.

Before referencing an asset:

1. Confirm the file exists on disk at that exact path.
2. Confirm its directory is declared under `flutter: assets:` in `pubspec.yaml`. A file
   that exists but is undeclared fails the same way at runtime.
3. Match the project's naming and directory convention — the conventions file records it.

If the asset does not exist, say so and stop. Do not substitute a Material icon for a
missing brand asset, and do not write the path you expect the designer to export later.
A placeholder that looks plausible is worse than a blocked task, because the blocked task
gets resolved and the placeholder ships.

Use the project's existing loader. A project on `flutter_svg` uses `SvgPicture.asset` for
SVGs; introducing a second image library for one icon is a dependency added by accident.

## Match the house style

These are not correctness rules. They are the difference between a change that reads as
part of the codebase and one that reads as pasted in.

- **File names.** Follow the pattern already in use — `wallet_page.dart` in a project of
  `_page.dart` files, not `WalletScreen.dart`.
- **Class suffix.** If twelve routed widgets are named `*Page` and none are `*Screen`,
  the thirteenth is a `Page`. Count before choosing.
- **Widget base class.** Match what the project uses — `StatelessWidget`,
  `ConsumerWidget`, `HookWidget`. Introducing `flutter_hooks` into a project that does not
  use it is a stack decision disguised as a widget.
- **Imports.** Match the project's mix of `package:` and relative imports, and its use of
  barrel files. This one is worth checking rather than guessing; projects are consistent
  about it and the analyzer often enforces it.
- **Directory placement.** In this repository, follow the `app/lib/app`,
  `app/lib/features`, and `app/lib/core` layout recorded in `.agents/flutter-conventions.md`.
  There is no separate architecture skill dependency.

Everything `dart format` and `analysis_options.yaml` already enforce is not your concern —
run the formatter and let the analyzer speak.

## Common mistakes

- Grepping for the exact class name you had in mind, finding nothing, and treating that
  as proof nothing exists.
- Building a component in `core/widgets/` on its first use. Wait for the third — two
  usages that later diverge are cheaper to split than to un-merge.
- Copying a widget from another feature and editing it, instead of extracting the shared
  parts. This produces two widgets that drift, which is worse than either reuse or a clean
  second implementation.
- Inline `TextStyle` inside a `copyWith` chain, on the grounds that it is technically
  going through the theme. It is not.
- Referencing `assets/images/logo.png` because that is where a logo would obviously be.
