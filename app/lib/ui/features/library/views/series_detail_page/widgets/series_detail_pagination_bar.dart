import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/pagination/library_pagination_bar.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailPaginationBar extends ConsumerWidget {
  const SeriesDetailPaginationBar({
    super.key,
    required this.seriesId,
    required this.page,
    required this.totalPages,
    required this.isLoading,
    this.placement = LibraryPaginationPlacement.bottom,
  });

  final String seriesId;
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
    final SeriesDetailComicsCatalogController notifier = ref.read(
      seriesDetailComicsCatalogControllerProvider(seriesId).notifier,
    );
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: _paddingForPlacement(tokens),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GhostButton.icon(
            icon: LucideIcons.chevronsLeft,
            tooltip: l10n.seriesDetailPaginationFirst,
            onPressed: canGoPrevious ? notifier.goToFirstPage : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: l10n.seriesDetailPaginationPrevious,
            onPressed: canGoPrevious ? notifier.goToPreviousPage : null,
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
                ? () => notifier.goToNextPage(totalPages)
                : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronsRight,
            tooltip: l10n.seriesDetailPaginationLast,
            onPressed: canGoNext
                ? () => notifier.goToLastPage(totalPages)
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
