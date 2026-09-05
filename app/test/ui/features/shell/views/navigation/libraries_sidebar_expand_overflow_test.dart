import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets(
    'libraries chrome rows do not overflow during sidebar expand animation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final _FakeSettingsNotifier settings = _FakeSettingsNotifier(
        AppSetting(desktopSidebarExpanded: false),
      );

      final GoRouter router = GoRouter(
        initialLocation: '/home',
        routes: <RouteBase>[
          ShellRoute(
            builder: (BuildContext context, GoRouterState state, Widget child) {
              return ResponsiveAppShell(routeChild: child);
            },
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) =>
                    const Scaffold(body: Text('home-body')),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            settingsProvider.overrideWith(() => settings),
            currentLibraryProvider.overrideWith(
              () => _FakeCurrentLibraryNotifier(
                libraries: <LocalLibrary>[
                  _lib('a', 'Alpha'),
                  _lib('b', 'Beta'),
                ],
                currentId: 'a',
              ),
            ),
            scanLibraryControllerProvider.overrideWith(
              _IdleScanLibraryController.new,
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Expand collapsed rail through the full animation.
      await tester.tap(find.byIcon(LucideIcons.menu));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at expand frame $i',
        );
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Collapse back.
      await tester.tap(find.byIcon(LucideIcons.menu));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at collapse frame $i',
        );
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

LocalLibrary _lib(String id, String name) => (
  libraryId: id,
  kind: 'local',
  rootPath: 'C:\\libs\\$name',
  name: name,
  enabledFormatGroups: const <FormatGroup>[],
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: true,
  sidebarOrder: 0,
);

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this._setting);

  AppSetting _setting;

  @override
  Future<AppSetting> build() async => _setting;

  @override
  Future<void> setDesktopSidebarExpanded(bool value) async {
    _setting = _setting.copyWith(desktopSidebarExpanded: value);
    state = AsyncData(_setting);
  }
}

class _IdleScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}

class _FakeCurrentLibraryNotifier extends CurrentLibraryNotifier {
  _FakeCurrentLibraryNotifier({
    required this.libraries,
    required this.currentId,
  });

  final List<LocalLibrary> libraries;
  String? currentId;

  @override
  Future<CurrentLibraryState> build() async {
    return CurrentLibraryState(libraries: libraries, currentId: currentId);
  }
}
