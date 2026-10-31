import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_facet_counts_provider.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/md3e_home_page.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_aggregate_counts.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 生产首页入口：把 provider 数据组装为 [Md3eHomePage]。
class HomeMd3ePage extends ConsumerWidget {
  const HomeMd3ePage({super.key});

  static const HomePageCounts _emptyCounts = HomePageCounts(
    comicCount: 0,
    tagCount: 0,
    seriesCount: 0,
    authorCount: 0,
    libraryCount: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomePageCounts counts = ref
        .watch(homePageCountsStreamProvider)
        .maybeWhen(
          data: (HomePageCounts data) => data,
          orElse: () => _emptyCounts,
        );
    final HomeFacetCounts facets = ref
        .watch(homeFacetCountsProvider)
        .maybeWhen(
          data: (HomeFacetCounts data) => data,
          orElse: () => (parodyCount: 0, characterCount: 0),
        );
    final List<HomeLibraryStat> stats = ref
        .watch(homeLibraryStatsStreamProvider)
        .maybeWhen(
          data: (List<HomeLibraryStat> data) => data,
          orElse: () => const <HomeLibraryStat>[],
        );
    final List<LocalLibrary> libraries = ref
        .watch(currentLibraryStateProvider)
        .maybeWhen(
          data: (CurrentLibraryState state) => state.libraries,
          orElse: () => const <LocalLibrary>[],
        );

    final Map<String, HomeLibraryStat> statsById = <String, HomeLibraryStat>{
      for (final HomeLibraryStat stat in stats) stat.libraryId: stat,
    };
    final List<Md3eHomeLibraryDashboardRow> rows = libraries
        .map((LocalLibrary library) {
          final HomeLibraryStat? stat = statsById[library.libraryId];
          return Md3eHomeLibraryDashboardRow(
            libraryId: library.libraryId,
            displayName: localLibraryDisplayName(library),
            kind: isRemoteLibrary(library)
                ? Md3eHomeLibraryKind.remote
                : Md3eHomeLibraryKind.local,
            comicCount: stat?.comicCount ?? 0,
            seriesCount: stat?.seriesCount ?? 0,
            lastSyncedAt: stat?.lastSuccessfulSyncAt,
          );
        })
        .toList(growable: false);

    // 生产路径无 Md3eThemeScope，M3ETheme 回退到 Material 主题（不带字体）；此处补上应用字体。
    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: Md3eHomePage(
        libraries: rows,
        aggregateCounts: Md3eHomeAggregateCounts(
          comicCount: counts.comicCount,
          seriesCount: counts.seriesCount,
          authorCount: counts.authorCount,
          parodyCount: facets.parodyCount,
          characterCount: facets.characterCount,
          tagCount: counts.tagCount,
        ),
        onOpenNavigation: appShellPageNavigationOpener(context),
        onLibraryOpen: (String libraryId) =>
            context.go(LibrariesRoutes.library(libraryId)),
      ),
    );
  }
}
