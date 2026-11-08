import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_facet_counts_provider.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_layout.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'package:hentai_library/features/home/presentation/views/home/home_layout.dart';

/// 生产首页入口：把 provider 数据组装为 [HomeLayout]。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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

    return HomeLayout(
      aggregateCounts: HomeAggregateCounts(
        comicCount: counts.comicCount,
        seriesCount: counts.seriesCount,
        authorCount: counts.authorCount,
        parodyCount: facets.parodyCount,
        characterCount: facets.characterCount,
        tagCount: counts.tagCount,
      ),
      onOpenNavigation: appShellPageNavigationOpener(context),
      // 与历史 / 垃圾桶同款：push + Shell fade-through，返回可走 reverse。
      onOpenHistory: () => context.push('/history'),
      onOpenTrash: () => context.push('/trash'),
      onOpenAuthors: () => context.push('/metadata?tab=authors'),
      onOpenParodies: () => context.push('/metadata?tab=parodies'),
      onOpenCharacters: () => context.push('/metadata?tab=characters'),
      onOpenTags: () => context.push('/metadata?tab=tags'),
      libraryManagementSection: const HomeLibraryManagementPanel(),
    );
  }
}
