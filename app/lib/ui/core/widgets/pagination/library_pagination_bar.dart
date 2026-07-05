import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
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
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool canGoPrevious = !isLoading && page > 1;
    final bool canGoNext = !isLoading && page < totalPages;
    final LibraryCatalogController controller = ref.read(
      libraryCatalogControllerProvider.notifier,
    );
    return Padding(
      padding: _paddingForPlacement(tokens),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GhostButton.icon(
            icon: LucideIcons.chevronsLeft,
            tooltip: '首页',
            onPressed: canGoPrevious
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      controller.goToComicsFirstPage(),
                    LibraryPaginationTarget.series =>
                      controller.goToSeriesFirstPage(),
                  }
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: '上一页',
            onPressed: canGoPrevious
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      controller.goToComicsPreviousPage(),
                    LibraryPaginationTarget.series =>
                      controller.goToSeriesPreviousPage(),
                  }
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
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      controller.goToComicsNextPage(totalPages),
                    LibraryPaginationTarget.series =>
                      controller.goToSeriesNextPage(totalPages),
                  }
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronsRight,
            tooltip: '末页',
            onPressed: canGoNext
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      controller.goToComicsLastPage(totalPages),
                    LibraryPaginationTarget.series =>
                      controller.goToSeriesLastPage(totalPages),
                  }
                : null,
          ),
        ],
      ),
    );
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
    final AsyncValue<LibraryPageSnapshot> catalogAsync = ref.watch(
      libraryPageContentProvider,
    );
    final LibraryPageSnapshot? snapshot = catalogAsync.value;
    if (snapshot == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final LibraryPagination pagination = switch (target) {
      LibraryPaginationTarget.comics => snapshot.comicsPagination,
      LibraryPaginationTarget.series => snapshot.seriesPagination,
    };
    if (pagination.totalPages <= 1) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: LibraryPaginationBar(
        target: target,
        page: pagination.page,
        totalPages: pagination.totalPages,
        isLoading: catalogAsync.isLoading,
        placement: placement,
      ),
    );
  }
}
