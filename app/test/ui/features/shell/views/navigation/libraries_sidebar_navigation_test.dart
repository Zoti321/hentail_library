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
import 'package:hentai_library/ui/features/shell/views/all_libraries_browse_page.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets('tapping library row selects current library and opens browse', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[_lib('a', 'Alpha'), _lib('b', 'Beta')],
      currentId: 'a',
    );
    late GoRouter router;
    await _pumpLibrariesShell(tester, fake, (GoRouter r) => router = r);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(fake.selectedIds, <String>['b']);
    expect(router.state.uri.path, '/libraries/b');
  });

  testWidgets('tapping libraries section opens all-libraries placeholder', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[_lib('a', 'Alpha')],
      currentId: 'a',
    );
    late GoRouter router;
    await _pumpLibrariesShell(tester, fake, (GoRouter r) => router = r);

    await tester.tap(find.text('漫画库').first);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, LibrariesRoutes.all);
    expect(find.byType(AllLibrariesBrowsePage), findsOneWidget);
    expect(find.textContaining('后续实现'), findsOneWidget);
  });

  testWidgets('/local redirects to current library browse', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[_lib('a', 'Alpha')],
      currentId: 'a',
    );
    late GoRouter router;
    await _pumpLibrariesShell(
      tester,
      fake,
      (GoRouter r) => router = r,
      initialLocation: '/local',
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/libraries/a');
  });

  testWidgets(
    'collapsed rail popup shows create actions then libraries and switches',
    (WidgetTester tester) async {
      final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
        libraries: <LocalLibrary>[_lib('a', 'Alpha'), _lib('b', 'Beta')],
        currentId: 'a',
      );
      late GoRouter router;
      await _pumpLibrariesShell(
        tester,
        fake,
        (GoRouter r) => router = r,
        viewportSize: const Size(900, 900),
      );

      await tester.tap(_librariesRailIcon());
      await tester.pumpAndSettle();

      expect(find.text('添加本地库'), findsOneWidget);
      expect(find.text('添加远程库'), findsOneWidget);
      expect(find.text('Alpha'), findsWidgets);
      expect(find.text('Beta'), findsWidgets);

      await tester.tap(find.text('Beta').last);
      await tester.pumpAndSettle();

      expect(fake.selectedIds, <String>['b']);
      expect(router.state.uri.path, '/libraries/b');
    },
  );

  testWidgets(
    'collapsed rail popup with no libraries shows only create actions',
    (WidgetTester tester) async {
      final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
        libraries: const <LocalLibrary>[],
        currentId: null,
      );
      await _pumpLibrariesShell(
        tester,
        fake,
        (_) {},
        viewportSize: const Size(900, 900),
      );

      await tester.tap(_librariesRailIcon());
      await tester.pumpAndSettle();

      expect(find.text('添加本地库'), findsOneWidget);
      expect(find.text('添加远程库'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
    },
  );

  testWidgets(
    'compact drawer closes when tapping library section or library row',
    (WidgetTester tester) async {
      final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
        libraries: <LocalLibrary>[_lib('a', 'Alpha'), _lib('b', 'Beta')],
        currentId: 'a',
      );
      late GoRouter router;
      await _pumpLibrariesShell(
        tester,
        fake,
        (GoRouter r) => router = r,
        viewportSize: const Size(400, 800),
      );

      openAppShellNavigationDrawer();
      await tester.pumpAndSettle();
      expect(appShellScaffoldKey.currentState?.isDrawerOpen, isTrue);
      expect(find.text('Beta'), findsOneWidget);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/libraries/b');
      expect(appShellScaffoldKey.currentState?.isDrawerOpen, isFalse);

      openAppShellNavigationDrawer();
      await tester.pumpAndSettle();
      expect(appShellScaffoldKey.currentState?.isDrawerOpen, isTrue);

      await tester.tap(find.text('漫画库').first);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, LibrariesRoutes.all);
      expect(appShellScaffoldKey.currentState?.isDrawerOpen, isFalse);
    },
  );

  testWidgets('unpinned libraries stay behind 更多 until expanded', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[
        _lib('a', 'Alpha'),
        _lib('b', 'Beta', pinned: false),
      ],
      currentId: 'a',
    );
    await _pumpLibrariesShell(tester, fake, (_) {});

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(find.text('更多'), findsOneWidget);

    await tester.tap(find.text('更多'));
    await tester.pump();

    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('更多 is hidden when every library is pinned', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[_lib('a', 'Alpha'), _lib('b', 'Beta')],
      currentId: 'a',
    );
    await _pumpLibrariesShell(tester, fake, (_) {});

    expect(find.text('更多'), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('expanded unpinned libraries indent text under 更多', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[
        _lib('a', 'Alpha'),
        _lib('b', 'Beta', pinned: false),
      ],
      currentId: 'a',
    );
    await _pumpLibrariesShell(tester, fake, (_) {});

    await tester.tap(find.text('更多'));
    await tester.pump();

    final double alphaLeft = tester.getTopLeft(find.text('Alpha')).dx;
    final double betaLeft = tester.getTopLeft(find.text('Beta')).dx;
    expect(betaLeft - alphaLeft, 8);
  });

  testWidgets('更多 chevron aligns with unpinned library overflow actions', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[
        _lib('a', 'Alpha'),
        _lib('b', 'Beta', pinned: false),
      ],
      currentId: 'a',
    );
    await _pumpLibrariesShell(tester, fake, (_) {});

    await tester.tap(find.text('更多'));
    await tester.pump();

    final Finder moreRow = find
        .ancestor(of: find.text('更多'), matching: find.byType(GestureDetector))
        .first;
    final Finder betaRow = find
        .ancestor(of: find.text('Beta'), matching: find.byType(GestureDetector))
        .first;

    final RenderBox moreChevron = tester.renderObject<RenderBox>(
      find.descendant(
        of: moreRow,
        matching: find.byIcon(LucideIcons.chevronDown),
      ),
    );
    final RenderBox betaOverflow = tester.renderObject<RenderBox>(
      find.descendant(
        of: betaRow,
        matching: find.byIcon(LucideIcons.ellipsisVertical),
      ),
    );

    expect(
      moreChevron.localToGlobal(Offset.zero).dx + moreChevron.size.width / 2,
      closeTo(
        betaOverflow.localToGlobal(Offset.zero).dx +
            betaOverflow.size.width / 2,
        0.5,
      ),
    );
  });
}

Finder _librariesRailIcon() {
  return find.byWidgetPredicate(
    (Widget widget) => widget is Icon && widget.icon == LucideIcons.library,
  );
}

LocalLibrary _lib(
  String id,
  String name, {
  bool pinned = true,
  int sidebarOrder = 0,
}) => (
  libraryId: id,
  kind: 'local',
  rootPath: 'C:\\libs\\$name',
  name: name,
  enabledFormatGroups: const <FormatGroup>[],
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: pinned,
  sidebarOrder: sidebarOrder,
);

Future<void> _pumpLibrariesShell(
  WidgetTester tester,
  _FakeCurrentLibraryNotifier fake,
  void Function(GoRouter router) onRouter, {
  String initialLocation = '/home',
  Size viewportSize = const Size(1280, 900),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
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
          GoRoute(
            path: LibrariesRoutes.root,
            redirect: (BuildContext context, GoRouterState state) {
              if (state.uri.path == LibrariesRoutes.root) {
                return LibrariesRoutes.all;
              }
              return null;
            },
            routes: <RouteBase>[
              GoRoute(
                path: LibrariesRoutes.allSegment,
                builder: (BuildContext context, GoRouterState state) =>
                    const AllLibrariesBrowsePage(),
              ),
              GoRoute(
                path: ':libraryId',
                builder: (BuildContext context, GoRouterState state) {
                  final String id = state.pathParameters['libraryId'] ?? '';
                  return Scaffold(body: Text('browse-$id'));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/local',
            builder: (BuildContext context, GoRouterState state) =>
                const LegacyLocalLibraryRedirectPage(),
          ),
        ],
      ),
    ],
  );
  onRouter(router);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        settingsProvider.overrideWith(_FakeSettingsNotifier.new),
        currentLibraryProvider.overrideWith(() => fake),
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
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSetting> build() async => AppSetting();
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

  List<LocalLibrary> libraries;
  String? currentId;
  final List<String> selectedIds = <String>[];

  @override
  Future<CurrentLibraryState> build() async {
    return CurrentLibraryState(libraries: libraries, currentId: currentId);
  }

  @override
  Future<void> select(String libraryId) async {
    selectedIds.add(libraryId);
    currentId = libraryId;
    state = AsyncData(
      CurrentLibraryState(libraries: libraries, currentId: currentId),
    );
  }

  @override
  Future<void> clear() async {
    currentId = null;
    state = AsyncData(
      CurrentLibraryState(libraries: libraries, currentId: null),
    );
  }

  @override
  Future<void> refresh() async {
    state = AsyncData(
      CurrentLibraryState(libraries: libraries, currentId: currentId),
    );
  }
}
