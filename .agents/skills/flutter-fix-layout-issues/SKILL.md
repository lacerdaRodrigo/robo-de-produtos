---
name: flutter-fix-layout-issues
description: Diagnose and fix Flutter layout exceptions such as RenderFlex overflow and unbounded constraints using the existing Android/iOS widget tree and project tools.
---

# Fix Flutter layout errors

Use the exact exception and the relevant widget tree to find the first constraint
failure. `RenderBox was not laid out` is often a downstream symptom; inspect the earlier
exception in the same output.

Common causes:

- A vertical scrollable inside an unconstrained `Column`: give it bounded height or use a
  layout that lets the scrollable own the available space.
- A `TextField` inside an unconstrained `Row`: wrap it with `Expanded` or `Flexible`.
- A `RenderFlex overflowed`: identify which child needs to wrap, scroll, shrink, or use
  available flexible space at the supported V15 width.
- `Incorrect use of ParentDataWidget`: ensure `Expanded`, `Flexible`, or `Positioned` is
  beneath the matching `Flex` or `Stack` parent.

Read the relevant V15 HTML state, design guide, and current parent/child widgets before
changing layout. Preserve the specified hierarchy and spacing; report a conflict between
the approved reference and a necessary constraint fix instead of silently redesigning it.

Use the Flutter CLI available in `app/`: format changed Dart files, run `flutter analyze`,
and run only the directly affected unit/widget test. Do not depend on Flutter MCP tools,
which are not configured for this project, and do not add broad tests or a Web workflow.
