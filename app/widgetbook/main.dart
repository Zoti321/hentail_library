import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'md3e_viewports.dart';
import 'md3e_widgetbook_app.dart';
import 'widgetbook_directories.dart';

/// Dev-only MD3E Lab catalog (not wired to production [go_router]).
///
/// Run: `flutter run -t widgetbook/main.dart`
void main() {
  runApp(
    Widgetbook(
      directories: buildWidgetbookDirectories(),
      appBuilder: md3eWidgetbookAppBuilder,
      addons: <WidgetbookAddon<dynamic>>[
        ViewportAddon(buildMd3eWidgetbookViewports()),
      ],
    ),
  );
}
