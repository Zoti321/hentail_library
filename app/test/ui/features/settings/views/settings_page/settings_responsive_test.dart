import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/navigation/desktop_sidebar.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_loaded_view.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_header.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/fakes/settings_test_fakes.dart';
import '../../../../../support/pump_localized_app.dart';

void main() {
  group('Settings list–detail', () {
    testWidgets(
      'wide shows master and detail with first category selected by default',
      (WidgetTester tester) async {
        await _pumpSettingsView(tester, viewportWidth: 700);

        expect(tester.takeException(), isNull);
        expect(find.text('设置'), findsWidgets);
        expect(find.text('个性化'), findsWidgets);
        expect(find.text('诊断与支持'), findsOneWidget);
        expect(find.text('关于'), findsOneWidget);
        expect(find.text('应用主题'), findsOneWidget);
        expect(find.text('检查更新'), findsNothing);
        _expectBackIcon(tester, findsOneWidget);
        _expectMenuIcon(tester, findsNothing);
        expect(find.byType(SettingsPageHeaderSection), findsOneWidget);
      },
    );

    testWidgets('wide switching master category changes detail content', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 700);

      await tester.tap(_masterCategoryFinder('关于'));
      await tester.pumpAndSettle();

      expect(find.text('检查更新'), findsOneWidget);
      expect(find.text('当前版本 v1.0.0'), findsOneWidget);
      expect(find.text('应用主题'), findsNothing);
    });

    testWidgets('narrow starts on master list without detail rows', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('个性化'), findsOneWidget);
      expect(find.text('诊断与支持'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
      expect(find.text('应用主题'), findsNothing);
      expect(find.text('检查更新'), findsNothing);
      _expectBackIcon(tester, findsOneWidget);
      _expectMenuIcon(tester, findsNothing);
    });

    testWidgets(
      'narrow drills into detail then header back returns to master',
      (WidgetTester tester) async {
        await _pumpSettingsView(tester, viewportWidth: 360);

        await tester.tap(find.text('关于'));
        await tester.pumpAndSettle();

        expect(find.text('检查更新'), findsOneWidget);
        expect(find.text('关于'), findsWidgets);

        await tester.tap(_backButtonFinder());
        await tester.pumpAndSettle();

        expect(find.text('检查更新'), findsNothing);
        expect(find.text('个性化'), findsOneWidget);
        expect(find.text('关于'), findsOneWidget);
      },
    );

    testWidgets('narrow header back from master leaves settings', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsShell(tester, viewportWidth: 360);

      expect(find.text('首页占位'), findsNothing);
      expect(find.text('设置'), findsOneWidget);

      await tester.tap(_backButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text('首页占位'), findsOneWidget);
      expect(find.text('设置'), findsNothing);
    });

    testWidgets('wide header back leaves settings', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsShell(tester, viewportWidth: 800);

      expect(find.text('设置'), findsWidgets);

      await tester.tap(_backButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text('首页占位'), findsOneWidget);
    });

    testWidgets('resize across compact breakpoint keeps selected category', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 700);

      await tester.tap(_masterCategoryFinder('诊断与支持'));
      await tester.pumpAndSettle();
      expect(find.text('详细诊断'), findsOneWidget);

      await _setViewport(tester, 360);
      await tester.pumpAndSettle();

      expect(find.text('详细诊断'), findsOneWidget);
      expect(find.text('诊断与支持'), findsWidgets);

      await _setViewport(tester, 700);
      await tester.pumpAndSettle();

      expect(find.text('详细诊断'), findsOneWidget);
      expect(find.text('应用主题'), findsNothing);
    });

    testWidgets(
      'compact theme row still uses chevron when in personalization',
      (WidgetTester tester) async {
        await _pumpSettingsView(tester, viewportWidth: 360);

        await tester.tap(find.text('个性化'));
        await tester.pumpAndSettle();

        expect(
          settingsThemeRowUsesChevronAction(SettingsLayoutTier.compact),
          isTrue,
        );
        expect(find.text('跟随系统'), findsNothing);
        expect(find.text('应用主题'), findsOneWidget);
      },
    );

    testWidgets('medium theme row shows preference text in personalization', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 700);

      // Theme + language rows both default to "跟随系统".
      expect(find.text('跟随系统'), findsNWidgets(2));
    });

    testWidgets('settings route hides app sidebar on wide shell', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsShell(tester, viewportWidth: 800);

      expect(find.byType(DesktopSidebar), findsNothing);
      expect(find.text('设置'), findsWidgets);
    });

    testWidgets('settings route has no compact drawer chrome', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsShell(tester, viewportWidth: 360);

      expect(find.byType(DesktopSidebar), findsNothing);
      expect(find.byType(Drawer), findsNothing);
      _expectMenuIcon(tester, findsNothing);
    });
  });
}

Future<void> _pumpSettingsView(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  await _setViewport(tester, viewportWidth);

  await pumpLocalizedApp(
    tester,
    wrapProviderScope: true,
    overrides: settingsViewTestOverrides(),
    home: Scaffold(
      body: SizedBox(
        width: viewportWidth,
        height: 800,
        child: const SettingsView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSettingsShell(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  await _setViewport(tester, viewportWidth);

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
            builder: (BuildContext context, GoRouterState state) {
              return const Center(child: Text('首页占位'));
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsView();
            },
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...settingsViewTestOverrides(),
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
  await tester.pumpAndSettle();
  router.go('/settings');
  await tester.pumpAndSettle();
}

Future<void> _setViewport(WidgetTester tester, double viewportWidth) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Finder _masterCategoryFinder(String label) {
  // Wide layout may show the category once in master and again as detail title.
  return find.text(label).first;
}

Finder _backButtonFinder() {
  return find.byWidgetPredicate(
    (Widget widget) => widget is Icon && widget.icon == LucideIcons.arrowLeft,
  );
}

void _expectBackIcon(WidgetTester tester, Matcher matcher) {
  expect(_backButtonFinder(), matcher);
}

void _expectMenuIcon(WidgetTester tester, Matcher matcher) {
  expect(
    find.byWidgetPredicate(
      (Widget widget) => widget is Icon && widget.icon == LucideIcons.menu,
    ),
    matcher,
  );
}

class _IdleScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}
