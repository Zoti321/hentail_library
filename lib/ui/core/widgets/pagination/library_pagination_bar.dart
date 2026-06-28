import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LibraryPaginationBar extends ConsumerWidget {
  const LibraryPaginationBar({
    super.key,
    required this.totalCount,
    required this.page,
    required this.totalPages,
    required this.isLoading,
  });

  final int totalCount;
  final int page;
  final int totalPages;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totalCount <= 0 || totalPages <= 0) {
      return const SizedBox.shrink();
    }
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool canGoPrevious = !isLoading && page > 1;
    final bool canGoNext = !isLoading && page < totalPages;
    return Padding(
      padding: EdgeInsets.only(
        top: tokens.spacing.md,
        bottom: tokens.spacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GhostButton.icon(
            icon: LucideIcons.chevronsLeft,
            tooltip: '首页',
            onPressed: canGoPrevious
                ? () {
                    ref
                        .read(libraryComicsPageIndexProvider.notifier)
                        .goToFirstPage();
                  }
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: '上一页',
            onPressed: canGoPrevious
                ? () {
                    ref
                        .read(libraryComicsPageIndexProvider.notifier)
                        .goToPreviousPage();
                  }
                : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
            child: Text(
              '共 $totalCount 本 · 第 $page / $totalPages 页',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronRight,
            tooltip: '下一页',
            onPressed: canGoNext
                ? () {
                    ref
                        .read(libraryComicsPageIndexProvider.notifier)
                        .goToNextPage(totalPages);
                  }
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronsRight,
            tooltip: '末页',
            onPressed: canGoNext
                ? () {
                    ref
                        .read(libraryComicsPageIndexProvider.notifier)
                        .goToLastPage(totalPages);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class LibraryPaginationBarSliver extends ConsumerWidget {
  const LibraryPaginationBarSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PagedResult<Comic>> pageAsync = ref.watch(
      libraryComicsPageProvider,
    );
    return pageAsync.when(
      data: (PagedResult<Comic> page) {
        return SliverToBoxAdapter(
          child: LibraryPaginationBar(
            totalCount: page.totalCount,
            page: page.page,
            totalPages: page.totalPages,
            isLoading: false,
          ),
        );
      },
      loading: () {
        final int currentPage = ref.watch(libraryComicsPageIndexProvider);
        return SliverToBoxAdapter(
          child: LibraryPaginationBar(
            totalCount: 1,
            page: currentPage,
            totalPages: 1,
            isLoading: true,
          ),
        );
      },
      error: (Object _, StackTrace _) =>
          const SliverToBoxAdapter(child: SizedBox.shrink()),
      skipLoadingOnReload: true,
    );
  }
}
