---
name: responsive-adaptive
description: Adapt Flutter layouts to the actual available space on Android and iOS phones/tablets. Use when changing layout code, handling an overflow, or translating a single-width V15 screen.
---

# Responsive layout for the V15 app

Read the corresponding state in `design-app/mobile-v15/index.html`,
`docs/guias/design-v15.md`, and the current layout code before choosing a size or
breakpoint. The HTML and guide are the visual contract; the artboard is a reference, not
a hardcoded device width.

- Use `LayoutBuilder` when a component must respond to its parent's constraints.
- Use `MediaQuery.sizeOf(context)` for decisions made by the screen shell.
- Support the Android/iOS window sizes required by V15, including the phone/tablet cases
  defined there. Do not add desktop or Flutter Web behavior as part of this app cycle.
- Reuse an existing breakpoint or token if the app already defines the needed rule. Do
  not create a universal `core/layout/breakpoints.dart` path or adopt generic 600/840px
  thresholds without evidence in the project design.
- If a new breakpoint is required by the approved layout, put it with the existing app
  shell/layout code and name it semantically. Keep its value traceable to V15 behavior.
- Prefer `Expanded`, `Flexible`, and bounded constraints to overflow-prone fixed widths.
  Resolve spacing and dimensions through `context.tokens` when those values are part of
  the design system.

Verify the affected width cases through only the directly related widget tests allowed by
`AGENTS.md`. Do not introduce a separate responsive test suite or Web test.
