import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_facet_counts_provider.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/md3e_home_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

    return Md3eHomePage(
      aggregateCounts: Md3eHomeAggregateCounts(
        comicCount: counts.comicCount,
        seriesCount: counts.seriesCount,
        authorCount: counts.authorCount,
        parodyCount: facets.parodyCount,
        characterCount: facets.characterCount,
        tagCount: counts.tagCount,
      ),
      onOpenNavigation: appShellPageNavigationOpener(context),
      onOpenHistory: () => context.go('/history'),
      onOpenTrash: () => context.go('/trash'),
      libraryManagementSection: const HomeLibraryManagementPanel(),
    );
  }
}
