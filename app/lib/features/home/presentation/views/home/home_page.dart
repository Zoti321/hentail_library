import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_layout.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/shared/di/app_navigator_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'package:hentai_library/features/home/presentation/views/home/home_layout.dart';

/// 生产首页入口：把 provider 数据组装为 [HomeLayout]。
class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.libraryManagementSection});

  /// 由 bootstrap 注入的库管理面板（避免 home → library_admin，ADR-0045）。
  final Widget? libraryManagementSection;

  static const HomePageCounts _emptyCounts = HomePageCounts(
    comicCount: 0,
    tagCount: 0,
    seriesCount: 0,
    authorCount: 0,
    parodyCount: 0,
    characterCount: 0,
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
    final ReadingActivityStats activityStats = ref
        .watch(readingActivityStatsStreamProvider)
        .maybeWhen(
          data: (ReadingActivityStats data) => data,
          orElse: () => ReadingActivityStats.empty,
        );

    return HomeLayout(
      aggregateCounts: HomeAggregateCounts(
        comicCount: counts.comicCount,
        seriesCount: counts.seriesCount,
        authorCount: counts.authorCount,
        parodyCount: counts.parodyCount,
        characterCount: counts.characterCount,
        tagCount: counts.tagCount,
      ),
      activityStats: activityStats,
      onOpenNavigation: appShellPageNavigationOpener(context),
      // 与历史 / 垃圾桶同款：push + Shell fade-through，返回可走 reverse。
      onOpenHistory: () => ref.read(appNavigatorProvider).pushHistory(),
      onOpenTrash: () => ref.read(appNavigatorProvider).pushTrash(),
      onOpenAuthors: () =>
          ref.read(appNavigatorProvider).pushMetadata(tab: 'authors'),
      onOpenParodies: () =>
          ref.read(appNavigatorProvider).pushMetadata(tab: 'parodies'),
      onOpenCharacters: () =>
          ref.read(appNavigatorProvider).pushMetadata(tab: 'characters'),
      onOpenTags: () =>
          ref.read(appNavigatorProvider).pushMetadata(tab: 'tags'),
      libraryManagementSection:
          libraryManagementSection ?? const SizedBox.shrink(),
    );
  }
}
