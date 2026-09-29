---
name: flutter-add-widget-preview
description: Create or update a Flutter widget preview when explicitly requested or when a local render is needed to compare a changed V15 screen with its HTML reference.
---

# Flutter widget previews

The Flutter SDK available to this project exposes `package:flutter/widget_previews.dart`
and the `flutter widget-preview` command. The existing V15 preview entry point is
`app/lib/app/previews/v15.dart`.

Before adding a preview, inspect that entry point and the directly related screen. Reuse
the V15 app shell and `TemaRadar` light/dark themes. Keep preview-only sample values
clearly illustrative; never feed them into production state or treat them as backend
data.

Previews are optional rendering aids. Add or update one only when the user requests it or
when it materially helps compare a changed screen with the approved V15 HTML. Do not add
a preview to every modified widget as a blanket requirement. A preview workflow does not
authorize adding a Flutter Web target or running Web tests/builds.

When a preview is needed, follow the SDK command shown by `flutter widget-preview --help`
and use `flutter widget-preview start` from `app/`. If the local environment cannot start
the preview, report that and use the allowed relevant widget test or existing rendering
path; do not add dependencies or conditional native mocks just to satisfy this skill.
