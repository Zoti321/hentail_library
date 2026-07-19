import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
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
    final l10n = context.l10n;
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
            tooltip: l10n.seriesDetailPaginationFirst,
            onPressed: canGoPrevious
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      ref
                          .read(libraryComicsCatalogControllerProvider.notifier)
                          .goToFirstPage(),
                    LibraryPaginationTarget.series =>
                      ref
                          .read(librarySeriesCatalogControllerProvider.notifier)
                          .goToFirstPage(),
                  }
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: l10n.seriesDetailPaginationPrevious,
            onPressed: canGoPrevious
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      ref
                          .read(libraryComicsCatalogControllerProvider.notifier)
                          .goToPreviousPage(),
                    LibraryPaginationTarget.series =>
                      ref
                          .read(librarySeriesCatalogControllerProvider.notifier)
                          .goToPreviousPage(),
                  }
                : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
            child: Text(
              l10n.seriesDetailPaginationPage(page, totalPages),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronRight,
            tooltip: l10n.seriesDetailPaginationNext,
            onPressed: canGoNext
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      ref
                          .read(libraryComicsCatalogControllerProvider.notifier)
                          .goToNextPage(totalPages),
                    LibraryPaginationTarget.series =>
                      ref
                          .read(librarySeriesCatalogControllerProvider.notifier)
                          .goToNextPage(totalPages),
                  }
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronsRight,
            tooltip: l10n.seriesDetailPaginationLast,
            onPressed: canGoNext
                ? () => switch (target) {
                    LibraryPaginationTarget.comics =>
                      ref
                          .read(libraryComicsCatalogControllerProvider.notifier)
                          .goToLastPage(totalPages),
                    LibraryPaginationTarget.series =>
                      ref
                          .read(librarySeriesCatalogControllerProvider.notifier)
                          .goToLastPage(totalPages),
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
    switch (target) {
      case LibraryPaginationTarget.comics:
        final AsyncValue<LibraryComicsCatalogState> catalogAsync = ref.watch(
          libraryComicsCatalogContentProvider,
        );
        final LibraryComicsCatalogState? catalog = catalogAsync.value;
        if (catalog == null || catalog.pagination.totalPages <= 1) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: LibraryPaginationBar(
            target: target,
            page: catalog.pagination.page,
            totalPages: catalog.pagination.totalPages,
            isLoading: catalogAsync.isLoading,
            placement: placement,
          ),
        );
      case LibraryPaginationTarget.series:
        final AsyncValue<LibrarySeriesCatalogState> catalogAsync = ref.watch(
          librarySeriesCatalogContentProvider,
        );
        final LibrarySeriesCatalogState? catalog = catalogAsync.value;
        if (catalog == null || catalog.pagination.totalPages <= 1) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: LibraryPaginationBar(
            target: target,
            page: catalog.pagination.page,
            totalPages: catalog.pagination.totalPages,
            isLoading: catalogAsync.isLoading,
            placement: placement,
          ),
        );
    }
  }
}
