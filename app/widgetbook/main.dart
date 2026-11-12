import 'package:flutter/material.dart';
import 'package:hentai_library/composition/window_composition.dart';
import 'package:widgetbook/widgetbook.dart';

import 'catalog/widgetbook_directories.dart';
import 'shell/md3e_viewports.dart';
import 'shell/md3e_widgetbook_app.dart';
import 'shell/md3e_widgetbook_theme_addon.dart';

/// Dev-only MD3E Lab catalog (not wired to production [go_router]).
///
/// Run: `flutter run -t widgetbook/main.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurePreviewWindow();
  runApp(
    AppWindowHost(
      child: Widgetbook(
        directories: buildWidgetbookDirectories(),
        appBuilder: md3eWidgetbookAppBuilder,
        addons: <WidgetbookAddon<dynamic>>[
          buildMd3eWidgetbookThemeAddon(),
          ViewportAddon(buildMd3eWidgetbookViewports()),
        ],
      ),
    ),
  );
}
