part of 'library_page_widgets.dart';

class _LibraryCatalogLoadingSliver extends StatelessWidget {
  const _LibraryCatalogLoadingSliver({
    required this.layoutTier,
    required this.horizontalPadding,
  });

  final LibraryLayoutTier layoutTier;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: libraryGridDelegateForTokens(tokens, layoutTier),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) => const CatalogCoverSkeletonTile(),
          childCount: 8,
        ),
      ),
    );
  }
}

class _LibraryCatalogEmptySliver extends ConsumerWidget {
  const _LibraryCatalogEmptySliver({
    required this.entity,
    required this.isTableEmpty,
  });

  final LibraryDisplayTarget entity;
  final bool isTableEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final LibraryEmptyStateContent content = resolveLibraryEmptyStateContent(
      l10n: context.l10n,
      entity: entity,
      isTableEmpty: isTableEmpty,
    );
    final IconData icon = switch (content.icon) {
      LibraryEmptyStateIcon.library => LucideIcons.library,
      LibraryEmptyStateIcon.listFilter => LucideIcons.listFilter,
    };
    Widget emptyAction({
      required IconData actionIcon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return Padding(
        padding: EdgeInsets.only(top: tokens.spacing.sm),
        child: GhostButton.iconText(
          icon: actionIcon,
          text: label,
          onPressed: onPressed,
          iconSize: 16,
          borderRadius: tokens.radius.md,
          foregroundColor: cs.primary,
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: 80,
          bottom: tokens.layout.contentHorizontalPadding,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spacing.md,
            children: <Widget>[
              Icon(icon, size: 56, color: cs.hentai.textTertiary),
              Text(
                content.title,
                style: TextStyle(
                  fontSize: tokens.text.titleSm,
                  fontWeight: FontWeight.w600,
                  color: cs.hentai.textPrimary,
                ),
              ),
              Text(
                content.hint,
                style: TextStyle(
                  fontSize: tokens.text.bodySm,
                  color: cs.hentai.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (content.showManagePathsEntry)
                emptyAction(
                  actionIcon: LucideIcons.folderTree,
                  label: context.l10n.libraryManageScanPaths,
                  onPressed: () => context.go('/paths'),
                ),
              if (content.showClearFilters)
                emptyAction(
                  actionIcon: LucideIcons.listFilter,
                  label: context.l10n.libraryClearFilters,
                  onPressed: () {
                    ref
                        .read(libraryQueryIntentProvider.notifier)
                        .clearKeyword();
                    if (entity == LibraryDisplayTarget.comics) {
                      ref
                          .read(libraryComicsFilterResetProvider.notifier)
                          .resetAll();
                    } else {
                      ref
                          .read(librarySeriesFilterResetProvider.notifier)
                          .resetAll();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
