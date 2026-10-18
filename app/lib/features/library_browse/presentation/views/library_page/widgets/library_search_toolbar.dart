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
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.hentai.iconDefault,
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

class LibrarySearchField extends ConsumerStatefulWidget {
  const LibrarySearchField({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<LibrarySearchField> createState() => _LibrarySearchFieldState();
}

class _LibrarySearchFieldState extends ConsumerState<LibrarySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kLibrarySearchMaxWidth),
        child: CustomTextField(
          controller: _controller,
          hintText: l10n.librarySearchHint,
          onSubmitted: _handleSubmitSearch,
        ),
      ),
    );
  }

  void _handleSubmitSearch(String value) {
    final String query = value.trim();
    if (query.isEmpty) {
      showInfoToast(context, context.l10n.librarySearchKeywordEmpty);
      return;
    }
    final String encodedQuery = Uri.encodeQueryComponent(query);
    ref.read(appRouterProvider).push('/searched?q=$encodedQuery');
  }
}

class LibraryDisplayTargetTabs extends ConsumerWidget {
  const LibraryDisplayTargetTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final LibraryPageFacadeNotifier facade = ref.read(
      libraryPageFacadeProvider.notifier,
    );
    final AppLocalizations l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _UnderlineTab(
          label: l10n.libraryTabComics,
          isSelected: displayTarget == LibraryDisplayTarget.comics,
          onTap: () => facade.selectDisplayTarget(LibraryDisplayTarget.comics),
        ),
        const SizedBox(width: 16),
        _UnderlineTab(
          label: l10n.libraryTabSeries,
          isSelected: displayTarget == LibraryDisplayTarget.series,
          onTap: () => facade.selectDisplayTarget(LibraryDisplayTarget.series),
        ),
      ],
    );
  }
}

class LibraryDisplayTargetBottomBar extends ConsumerWidget {
  const LibraryDisplayTargetBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final AppLocalizations l10n = context.l10n;
    return ContentSwitcherBottomBar(
      items: <ContentSwitcherBottomBarItem>[
        (icon: LucideIcons.bookImage, label: l10n.libraryTabComics),
        (icon: LucideIcons.bookMarked, label: l10n.libraryTabSeries),
      ],
      selectedIndex: displayTarget == LibraryDisplayTarget.comics ? 0 : 1,
      onSelected: (int index) {
        ref
            .read(libraryPageFacadeProvider.notifier)
            .selectDisplayTarget(
              index == 0
                  ? LibraryDisplayTarget.comics
                  : LibraryDisplayTarget.series,
            );
      },
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  const _UnderlineTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? cs.primary : cs.hentai.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: label.length * 14.0,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
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
          foregroundColor: isCustomized ? cs.primary : cs.hentai.iconDefault,
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
        border: Border.all(color: cs.hentai.borderSubtle),
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
            foregroundColor: cs.hentai.iconDefault,
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
