import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum LibraryPaginationPlacement { top, bottom }

enum LibraryPaginationTarget { comics, series }

class LibraryPaginationBar extends ConsumerWidget {
  const LibraryPaginationBar({
    super.key,
    required this.target,
    required this.page,
    required this.totalPages,
    required this.isLoading,
    this.placement = LibraryPaginationPlacement.bottom,
  });

  final LibraryPaginationTarget target;
  final int page;
  final int totalPages;
  final bool isLoading;
  final LibraryPaginationPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading || totalPages <= 1) {
      return const SizedBox.shrink();
    }
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool canGoPrevious = !isLoading && page > 1;
    final bool canGoNext = !isLoading && page < totalPages;
    return Padding(
      padding: _paddingForPlacement(tokens),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GhostButton.icon(
            icon: LucideIcons.chevronsLeft,
            tooltip: '首页',
            onPressed: canGoPrevious
                ? () => _pageIndexNotifier(ref).goToFirstPage()
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: '上一页',
            onPressed: canGoPrevious
                ? () => _pageIndexNotifier(ref).goToPreviousPage()
                : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
            child: Text(
              '第 $page / $totalPages 页',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronRight,
            tooltip: '下一页',
            onPressed: canGoNext
                ? () => _pageIndexNotifier(ref).goToNextPage(totalPages)
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronsRight,
            tooltip: '末页',
            onPressed: canGoNext
                ? () => _pageIndexNotifier(ref).goToLastPage(totalPages)
                : null,
          ),
        ],
      ),
    );
  }

  dynamic _pageIndexNotifier(WidgetRef ref) {
    return switch (target) {
      LibraryPaginationTarget.comics =>
        ref.read(libraryComicsPageIndexProvider.notifier),
      LibraryPaginationTarget.series =>
        ref.read(librarySeriesPageIndexProvider.notifier),
    };
  }

  EdgeInsets _paddingForPlacement(AppThemeTokens tokens) {
    return switch (placement) {
      LibraryPaginationPlacement.top => EdgeInsets.only(
        bottom: tokens.spacing.sm,
      ),
      LibraryPaginationPlacement.bottom => EdgeInsets.only(
        top: tokens.spacing.md,
        bottom: tokens.spacing.lg,
      ),
    };
  }
}

class LibraryPaginationBarSliver extends ConsumerWidget {
  const LibraryPaginationBarSliver({
    super.key,
    required this.target,
    this.placement = LibraryPaginationPlacement.bottom,
  });

  final LibraryPaginationTarget target;
  final LibraryPaginationPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (target) {
      LibraryPaginationTarget.comics => _buildComicsSliver(ref),
      LibraryPaginationTarget.series => _buildSeriesSliver(ref),
    };
  }

  Widget _buildComicsSliver(WidgetRef ref) {
    final AsyncValue<PagedResult<Comic>> pageAsync = ref.watch(
      libraryComicsPageProvider,
    );
    return pageAsync.when(
      data: (PagedResult<Comic> page) {
        return SliverToBoxAdapter(
          child: LibraryPaginationBar(
            target: LibraryPaginationTarget.comics,
            page: page.page,
            totalPages: page.totalPages,
            isLoading: false,
            placement: placement,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (Object _, StackTrace _) =>
          const SliverToBoxAdapter(child: SizedBox.shrink()),
      skipLoadingOnReload: true,
    );
  }

  Widget _buildSeriesSliver(WidgetRef ref) {
    final AsyncValue<PagedResult<Series>> pageAsync = ref.watch(
      librarySeriesPageProvider,
    );
    return pageAsync.when(
      data: (PagedResult<Series> page) {
        return SliverToBoxAdapter(
          child: LibraryPaginationBar(
            target: LibraryPaginationTarget.series,
            page: page.page,
            totalPages: page.totalPages,
            isLoading: false,
            placement: placement,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (Object _, StackTrace _) =>
          const SliverToBoxAdapter(child: SizedBox.shrink()),
      skipLoadingOnReload: true,
    );
  }
}
