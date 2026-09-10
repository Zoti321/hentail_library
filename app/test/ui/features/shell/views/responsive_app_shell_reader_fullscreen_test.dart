import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/chrome/app_title_bar.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_fullscreen_controller.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets(
    'reader shell hides title bar in fullscreen and tolerates tiny height',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await _pumpReaderShell(
          tester,
          viewportSize: const Size(146.4, 20),
          readerFullscreen: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(AppTitleBar), findsNothing);
        expect(find.text('reader'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'reader shell does not overflow when title chrome meets a tiny viewport',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        // Mid fullscreen transition can briefly report a tiny content size while
        // in-app chrome is still visible; shell must not throw a RenderFlex overflow.
        await _pumpReaderShell(
          tester,
          viewportSize: const Size(146.4, 20),
          readerFullscreen: false,
        );

        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

Future<void> _pumpReaderShell(
  WidgetTester tester, {
  required Size viewportSize,
  required bool readerFullscreen,
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        settingsProvider.overrideWith(_FakeSettingsNotifier.new),
        scanLibraryControllerProvider.overrideWith(
          _IdleScanLibraryController.new,
        ),
        readerFullscreenControllerProvider.overrideWithValue(readerFullscreen),
      ],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        routerConfig: GoRouter(
          initialLocation: '/reader/c1',
          routes: <RouteBase>[
            ShellRoute(
              builder:
                  (BuildContext context, GoRouterState state, Widget child) {
                    return ResponsiveAppShell(routeChild: child);
                  },
              routes: <RouteBase>[
                GoRoute(
                  path: '/reader/:comicId',
                  builder: (BuildContext context, GoRouterState state) {
                    return const ColoredBox(
                      color: Colors.black,
                      child: Center(child: Text('reader')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSetting> build() async => AppSetting();
}

class _IdleScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}
