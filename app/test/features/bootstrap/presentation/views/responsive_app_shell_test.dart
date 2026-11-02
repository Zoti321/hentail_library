import 'package:flutter/material.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/home_md3e_page.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/patterns/md3e_home_page_header.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell.dart';
import 'package:hentai_library/shared/ui/shell/shell_compact_app_bar.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/responsive_app_shell.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets('compact shell shows a single page title header', (
    WidgetTester tester,
  ) async {
    await _pumpShellHome(tester, const Size(599, 900));

    expect(find.text('首页'), findsWidgets);
    expect(find.byType(Md3eHomePageHeader), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == Symbols.menu,
      ),
      findsOneWidget,
    );
  });

  testWidgets('medium shell shows MD3E desktop chrome', (
    WidgetTester tester,
  ) async {
    await _pumpShellHome(tester, const Size(800, 900));

    expect(tester.takeException(), isNull);
    expect(find.byType(Md3eDesktopShell), findsOneWidget);
    expect(find.byType(Md3eShellCompactAppBar), findsOneWidget);
  });
}

Future<void> _pumpShellHome(WidgetTester tester, Size viewportSize) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _shellHomeOverrides(),
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        builder: (BuildContext context, Widget? child) {
          final Brightness brightness = Theme.of(context).brightness;
          return M3ETheme(
            data: buildAppM3eThemeData(brightness),
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: GoRouter(
          initialLocation: '/home',
          routes: <RouteBase>[
            ShellRoute(
              builder:
                  (BuildContext context, GoRouterState state, Widget child) {
                    return ApplicationShell(routeChild: child);
                  },
              routes: <RouteBase>[
                GoRoute(
                  path: '/home',
                  builder: (BuildContext context, GoRouterState state) {
                    return const HomeMd3ePage();
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
  await tester.pump();
}

List<Override> _shellHomeOverrides() {
  const HomePageCounts counts = HomePageCounts(
    comicCount: 0,
    tagCount: 0,
    seriesCount: 0,
    authorCount: 0,
    libraryCount: 0,
  );
  return <Override>[
    settingsProvider.overrideWith(_FakeSettingsNotifier.new),
    homePageCountsStreamProvider.overrideWith(
      (Ref ref) => Stream<HomePageCounts>.value(counts),
    ),
    homeLibraryAlertsStreamProvider.overrideWith(
      (Ref ref) =>
          Stream<List<HomeLibraryAlert>>.value(const <HomeLibraryAlert>[]),
    ),
    scanLibraryControllerProvider.overrideWith(_IdleScanLibraryController.new),
    ...sharedLibraryStateOverrides(),
    ...bootstrapCompositionOverrides(),
  ];
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSetting> build() async => AppSetting();
}

class _IdleScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}
