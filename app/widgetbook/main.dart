import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'widgetbook_directories.dart';
import 'package:widgetbook/widgetbook.dart';

/// Dev-only design catalog entry (not wired to production [go_router]).
///
/// Run: `flutter run -t widgetbook/main.dart`
void main() {
  runApp(
    Widgetbook.material(
      directories: buildWidgetbookDirectories(),
      addons: <WidgetbookAddon<dynamic>>[
        MaterialThemeAddon(
          themes: <WidgetbookTheme<ThemeData>>[
            WidgetbookTheme(
              name: 'Light',
              data: buildAppTheme(Brightness.light),
            ),
            WidgetbookTheme(name: 'Dark', data: buildAppTheme(Brightness.dark)),
          ],
        ),
        ViewportAddon(<ViewportData>[
          const ViewportData(
            name: 'Compact',
            width: 390,
            height: 844,
            pixelRatio: 1,
            platform: TargetPlatform.android,
          ),
          const ViewportData(
            name: 'Medium',
            width: 800,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
          const ViewportData(
            name: 'Expanded',
            width: 1280,
            height: 800,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
        ]),
      ],
    ),
  );
}
