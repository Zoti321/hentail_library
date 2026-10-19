part of 'library_page_widgets.dart';

class LibraryPageHeaderToolbar extends ConsumerWidget {
  const LibraryPageHeaderToolbar({
    super.key,
    required this.layoutTier,
    this.onOpenFilterSort,
    this.onOpenNavigation,
  });

  final LibraryLayoutTier layoutTier;
  final VoidCallback? onOpenFilterSort;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showCountChips = libraryHeaderShowsCountChips(layoutTier);
    final bool showActiveCountChipOnly = libraryHeaderShowsActiveCountChipOnly(
      layoutTier,
    );
    final bool showDisplayTargetTabs = libraryHeaderShowsDisplayTargetTabs(
      layoutTier,
    );
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (onOpenNavigation != null) ...<Widget>[
                        GhostButton.icon(
                          icon: LucideIcons.menu,
                          semanticLabel: context.l10n.shellOpenNavMenu,
                          tooltip: '',
                          iconSize: 16,
                          size: 32,
                          borderRadius: 8,
                          foregroundColor: Theme.of(context).hentai.iconDefault,
                          hoverColor: Theme.of(context).hoverColor,
                          overlayColor: Theme.of(context).hoverColor,
                          onPressed: onOpenNavigation,
                        ),
                        const SizedBox(width: 8),
                      ],
                      LibraryPageHeader(
                        layoutTier: layoutTier,
                        showCountChips: showCountChips,
                        showActiveCountChipOnly: showActiveCountChipOnly,
                      ),
                    ],
                  ),
                ),
              ),
              if (onOpenFilterSort != null)
                _LibraryCompactToolbar(
                  layoutTier: layoutTier,
                  onOpenFilterSort: onOpenFilterSort!,
                )
              else
                const _LegacyLibraryToolbar(),
            ],
          ),
          if (showDisplayTargetTabs) const LibraryDisplayTargetTabs(),
        ],
      ),
    );
  }
}

class LibraryContentSearchSliver extends ConsumerWidget {
  const LibraryContentSearchSliver({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
    this.initialQuery = '',
  });

  final LibraryLayoutTier layoutTier;
  final double horizontalPadding;
  final String initialQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        tokens.layout.contentVerticalPadding,
        horizontalPadding,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LibrarySearchField(initialQuery: initialQuery),
            const SizedBox(height: kLibrarySearchToGridSpacing),
          ],
        ),
      ),
    );
  }
}

class _LibraryCompactToolbar extends ConsumerWidget {
  const _LibraryCompactToolbar({
    required this.layoutTier,
    required this.onOpenFilterSort,
  });

  final LibraryLayoutTier layoutTier;
  final VoidCallback onOpenFilterSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool isCustomized = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.isFilterSortCustomized,
      ),
    );
    final AppLocalizations l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: libraryToolbarActionSpacing(layoutTier),
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.listFilter,
          tooltip: l10n.libraryFilterSortTooltip,
          semanticLabel: l10n.libraryFilterSortSemantic,
          iconSize: 16,
          size: 32,
          borderRadius: 8,
          foregroundColor: isCustomized
              ? cs.primary
              : context.hentai.iconDefault,
          hoverColor: theme.hoverColor,
          overlayColor: theme.hoverColor,
          delayTooltipThreeSeconds: true,
          onPressed: onOpenFilterSort,
        ),
        _LibraryOverflowMenuButton(layoutTier: layoutTier),
        _LibraryPageSizeMenuButton(layoutTier: layoutTier),
      ],
    );
  }
}

class _LegacyLibraryToolbar extends ConsumerWidget {
  const _LegacyLibraryToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hentai.borderSubtle),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GhostButton.icon(
            icon: LucideIcons.rotateCw,
            tooltip: l10n.libraryRefresh,
            semanticLabel: l10n.libraryRefresh,
            iconSize: 16,
            size: 28,
            borderRadius: 6,
            foregroundColor: context.hentai.iconDefault,
            hoverColor: theme.hoverColor,
            overlayColor: theme.hoverColor,
            delayTooltipThreeSeconds: true,
            onPressed: () {
              ref.read(libraryRefreshActionProvider).call();
            },
          ),
          const SizedBox(width: 8),
          const FilterPopupButton(),
          const SizedBox(width: 8),
          const SortPopupButton(),
        ],
      ),
    );
  }
}
