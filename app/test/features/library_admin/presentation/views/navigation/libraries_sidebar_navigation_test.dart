import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/scan_interval.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/responsive_app_shell.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

/// MD3E shell：库 flyout / compact sheet 选库导航（非 legacy Libraries 侧栏分区）。
void main() {
  testWidgets('library flyout selects current library and opens browse', (
    WidgetTester tester,
  ) async {
    final _FakeCurrentLibraryNotifier fake = _FakeCurrentLibraryNotifier(
      libraries: <LocalLibrary>[_lib('a', 'Alpha'), _lib('b', 'Beta')],
      currentId: 'a',
    );
    late GoRouter router;
    await _pumpLibrariesShell(tester, fake, (GoRouter r) => router = r);

    await _openLibraryFlyout(tester);

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsWidgets);

    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(fake.selectedIds, <String>['b']);
    expect(router.state.uri.path, '/libraries/b');
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

  testWidgets('collapsed rail flyout lists libraries for browse switch', (
    WidgetTester tester,
  ) async {
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
      setting: AppSetting(desktopSidebarExpanded: false),
    );

    await _openLibraryFlyout(tester);

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsWidgets);

    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(fake.selectedIds, <String>['b']);
    expect(router.state.uri.path, '/libraries/b');
  });

  testWidgets('compact modal navigation closes after picking a library', (
    WidgetTester tester,
  ) async {
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
    expect(find.byType(Md3eNavigationRail), findsOneWidget);

    await tester.tap(find.text('漫画库').first);
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/libraries/b');
    expect(find.byType(Md3eNavigationRail), findsNothing);
  });
}

Finder _librariesRailIcon() {
  return find.byWidgetPredicate(
    (Widget widget) => widget is Icon && widget.icon == LucideIcons.library,
  );
}

Future<void> _openLibraryFlyout(WidgetTester tester) async {
  final Finder libraryLabel = find.text('漫画库');
  final Finder target = libraryLabel.evaluate().isNotEmpty
      ? libraryLabel.first
      : _librariesRailIcon().first;
  final Offset location = tester.getCenter(target);
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveTo(location);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
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
  enabledResourceFormatCategories: const <ResourceFormatCategory>[],
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
  AppSetting? setting,
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ApplicationShell(routeChild: child);
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
                    const Scaffold(body: Text('all-libraries')),
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
        settingsProvider.overrideWith(
          () => _FakeSettingsNotifier(setting ?? AppSetting()),
        ),
        currentLibraryProvider.overrideWith(() => fake),
        scanLibraryControllerProvider.overrideWith(
          _IdleScanLibraryController.new,
        ),
        ...sharedLibraryStateOverrides(),
        ...bootstrapCompositionOverrides(),
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
  _FakeSettingsNotifier([this._setting]);

  final AppSetting? _setting;

  @override
  Future<AppSetting> build() async => _setting ?? AppSetting();
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
