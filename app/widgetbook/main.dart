import 'package:flutter/material.dart';

import 'md3e_viewports.dart';
import 'widgetbook_directories.dart';

import 'package:widgetbook/widgetbook.dart';

/// Dev-only MD3E Lab catalog (not wired to production [go_router]).
///
/// Run: `flutter run -t widgetbook/main.dart`
void main() {
  runApp(
    Widgetbook.material(
      directories: buildWidgetbookDirectories(),
      addons: <WidgetbookAddon<dynamic>>[
        ViewportAddon(buildMd3eWidgetbookViewports()),
      ],
    ),
  );
}
