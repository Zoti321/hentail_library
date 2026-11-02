import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_facet_counts_provider.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/home_md3e_page.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/md3e_home_page.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/patterns/md3e_home_page_header.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_dashboard_stats_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/home_library_management_panel.dart';

import 'package:hentai_library/features/library_admin/domain/current_library_state.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/scan_interval.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/ports/library_management_port.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets(
    'production home renders aggregate stats and library management panel',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
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
              routes: <RouteBase>[
                GoRoute(
                  path: '/',
                  builder: (BuildContext context, GoRouterState state) {
                    return const Scaffold(body: HomeMd3ePage());
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Md3eHomePage), findsOneWidget);
      expect(find.byType(Md3eHomePageHeader), findsOneWidget);
      expect(find.byType(HomeLibraryManagementPanel), findsOneWidget);
      expect(find.text('Local Lib'), findsOneWidget);
      expect(find.text('Remote Lib'), findsOneWidget);
      final M3EThemeData theme = M3ETheme.of(
        tester.element(find.byType(Md3eHomePage)),
      );
      expect(theme.typeScale.titleMedium.fontFamily, kMd3eAppFontFamily);
      expect(theme.typeScale.bodyMedium.fontFamily, kMd3eAppFontFamily);
    },
  );
}

List<Override> _overrides() {
  const HomePageCounts counts = HomePageCounts(
    comicCount: 4,
    tagCount: 5,
    seriesCount: 2,
    authorCount: 6,
    libraryCount: 2,
  );
  final CurrentLibraryState state = CurrentLibraryState(
    libraries: <LocalLibrary>[
      _library(id: 'local', name: 'Local Lib', kind: 'local', order: 0),
      _library(id: 'remote', name: 'Remote Lib', kind: 'remote', order: 1),
    ],
    currentId: 'local',
  );
  return <Override>[
    homePageCountsStreamProvider.overrideWith(
      (Ref ref) => Stream<HomePageCounts>.value(counts),
    ),
    homeFacetCountsProvider.overrideWith(
      (Ref ref) async => (parodyCount: 7, characterCount: 8),
    ),
    libraryDashboardStatsStreamProvider.overrideWith(
      (Ref ref) => Stream<List<HomeLibraryStat>>.value(const <HomeLibraryStat>[
        HomeLibraryStat(libraryId: 'local', comicCount: 3, seriesCount: 1),
        HomeLibraryStat(libraryId: 'remote', comicCount: 1, seriesCount: 1),
      ]),
    ),
    currentLibraryStateProvider.overrideWithValue(AsyncValue.data(state)),
    libraryScanActivityStateProvider.overrideWithValue((
      running: false,
      scanMode: ScanMode.incremental,
    )),
    libraryMetadataRefreshTargetLibraryIdStateProvider.overrideWithValue(null),
    libraryManagementPortProvider.overrideWithValue(_NoopLibraryManagementPort()),
  ];
}

class _NoopLibraryManagementPort implements LibraryManagementPort {
  @override
  Future<void> addLocalLibrary(BuildContext context) async {}

  @override
  Future<void> addRemoteLibrary(BuildContext context) async {}

  @override
  Future<void> deleteLibrary(
    BuildContext context,
    LocalLibrary library, {
    bool navigateAfter = true,
  }) async {}

  @override
  Future<void> editLibrarySettings(
    BuildContext context,
    LocalLibrary library,
  ) async {}

  @override
  Future<void> editRemoteLibrary(
    BuildContext context,
    LocalLibrary library,
  ) async {}

  @override
  void goAllLibraries(BuildContext context) {}

  @override
  void goCurrentLibraryBrowse(BuildContext context) {}

  @override
  Future<void> openLibrary(BuildContext context, String libraryId) async {}

  @override
  Future<void> scanAllLibraries({ScanMode mode = ScanMode.incremental}) async {}

  @override
  Future<void> scanLibrary(
    BuildContext context,
    String libraryId, {
    ScanMode mode = ScanMode.incremental,
    bool navigate = false,
  }) async {}
}

LocalLibrary _library({
  required String id,
  required String name,
  required String kind,
  required int order,
}) {
  return (
    libraryId: id,
    kind: kind,
    rootPath: '/tmp/$id',
    name: name,
    enabledResourceFormatCategories: const <ResourceFormatCategory>[],
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: false,
    sidebarOrder: order,
  );
}
