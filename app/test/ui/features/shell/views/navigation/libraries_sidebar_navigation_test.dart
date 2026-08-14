import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/library/format_group.dart';
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
}

LocalLibrary _lib(String id, String name) => (
  libraryId: id,
  kind: 'local',
  rootPath: 'C:\\libs\\$name',
  name: name,
  enabledFormatGroups: const <FormatGroup>[],
  username: '',
  allowHttp: false,
);

Future<void> _pumpLibrariesShell(
  WidgetTester tester,
  _FakeCurrentLibraryNotifier fake,
  void Function(GoRouter router) onRouter, {
  String initialLocation = '/home',
}) async {
  tester.view.physicalSize = const Size(1280, 900);
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

  final List<LocalLibrary> libraries;
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
