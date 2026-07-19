import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/home_page.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_header.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets('compact shell shows a single page title header', (
    WidgetTester tester,
  ) async {
    await _pumpShellHome(tester, const Size(360, 900));

    expect(tester.takeException(), isNull);
    expect(find.text('首页'), findsOneWidget);
    expect(find.byType(HomePageHeaderSection), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Icon && widget.icon == LucideIcons.menu,
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(HomePageHeaderToolbar),
        matching: find.text('扫描漫画库'),
      ),
      findsOneWidget,
    );
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
        routerConfig: GoRouter(
          initialLocation: '/home',
          routes: <RouteBase>[
            ShellRoute(
              builder:
                  (BuildContext context, GoRouterState state, Widget child) {
                    return ResponsiveAppShell(routeChild: child);
                  },
              routes: <RouteBase>[
                GoRoute(
                  path: '/home',
                  builder: (BuildContext context, GoRouterState state) {
                    return const HomePage();
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
  );
  return <Override>[
    settingsProvider.overrideWith(_FakeSettingsNotifier.new),
    homePageCountsStreamProvider.overrideWith(
      (Ref ref) => Stream<HomePageCounts>.value(counts),
    ),
    homeContinueReadingTop5StreamProvider.overrideWith(
      (Ref ref) => Stream<List<HomeContinueReadingEntry>>.value(
        const <HomeContinueReadingEntry>[],
      ),
    ),
    scanLibraryControllerProvider.overrideWith(_IdleScanLibraryController.new),
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
