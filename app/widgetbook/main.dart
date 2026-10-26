import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_window_manager_bindings.dart';
import 'package:widgetbook/widgetbook.dart';

import 'md3e_viewports.dart';
import 'md3e_widgetbook_app.dart';
import 'md3e_widgetbook_theme_addon.dart';
import 'widgetbook_directories.dart';

/// Dev-only MD3E Lab catalog (not wired to production [go_router]).
///
/// Run: `flutter run -t widgetbook/main.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMd3eWindowManager();
  runApp(
    Widgetbook(
      directories: buildWidgetbookDirectories(),
      appBuilder: md3eWidgetbookAppBuilder,
      addons: <WidgetbookAddon<dynamic>>[
        buildMd3eWidgetbookThemeAddon(),
        ViewportAddon(buildMd3eWidgetbookViewports()),
      ],
    ),
  );
}
