import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/value_objects/page_jump.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum LibraryPaginationPlacement { top, bottom }

class LibraryPaginationBar extends StatelessWidget {
  const LibraryPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onJump,
    this.placement = LibraryPaginationPlacement.bottom,
  });

  final int page;
  final int totalPages;
  final ValueChanged<PageJump> onJump;
  final LibraryPaginationPlacement placement;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Do not gate on catalog reload: disabling flips cursor/hover and drops
    // clicks while sync FRB fetch is in flight (felt as "偶发无反应").
    final bool canGoPrevious = page > 1;
    final bool canGoNext = page < totalPages;
    return Padding(
      padding: _paddingForPlacement(tokens),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GhostButton.icon(
            icon: LucideIcons.chevronsLeft,
            tooltip: l10n.seriesDetailPaginationFirst,
            onPressed: canGoPrevious ? () => onJump(PageJump.first) : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: l10n.seriesDetailPaginationPrevious,
            onPressed: canGoPrevious ? () => onJump(PageJump.previous) : null,
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
            onPressed: canGoNext ? () => onJump(PageJump.next) : null,
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronsRight,
            tooltip: l10n.seriesDetailPaginationLast,
            onPressed: canGoNext ? () => onJump(PageJump.last) : null,
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
