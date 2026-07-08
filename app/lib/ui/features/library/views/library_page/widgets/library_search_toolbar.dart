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
                          semanticLabel: '打开导航菜单',
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
          LibraryDisplayTargetTabs(
            showCountBadges: !showCountChips,
            layoutTier: layoutTier,
          ),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kLibrarySearchMaxWidth),
        child: CustomTextField(
          controller: _controller,
          hintText: '搜索…',
          onSubmitted: _handleSubmitSearch,
        ),
      ),
    );
  }

  void _handleSubmitSearch(String value) {
    final String query = value.trim();
    if (query.isEmpty) {
      showInfoToast(context, '关键词不能为空');
      return;
    }
    final String encodedQuery = Uri.encodeQueryComponent(query);
    appRouter.push('/searched?q=$encodedQuery');
  }
}

class LibraryDisplayTargetTabs extends ConsumerWidget {
  const LibraryDisplayTargetTabs({
    super.key,
    this.showCountBadges = false,
    this.layoutTier = LibraryLayoutTier.expanded,
  });

  final bool showCountBadges;
  final LibraryLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final int comicCount = ref.watch(libraryDisplayedComicCountProvider);
    final int seriesCount = ref.watch(libraryDisplayedSeriesCountProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _UnderlineTab(
          label: '漫画',
          isSelected: displayTarget == LibraryDisplayTarget.comics,
          badgeCount: showCountBadges ? comicCount : null,
          layoutTier: layoutTier,
          onTap: () => ref
              .read(libraryQueryIntentProvider.notifier)
              .setDisplayTarget(LibraryDisplayTarget.comics),
        ),
        const SizedBox(width: 16),
        _UnderlineTab(
          label: '系列',
          isSelected: displayTarget == LibraryDisplayTarget.series,
          badgeCount: showCountBadges ? seriesCount : null,
          layoutTier: layoutTier,
          onTap: () => ref
              .read(libraryQueryIntentProvider.notifier)
              .setDisplayTarget(LibraryDisplayTarget.series),
        ),
      ],
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  const _UnderlineTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.layoutTier = LibraryLayoutTier.expanded,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final LibraryLayoutTier layoutTier;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final LibraryTabBadgeMetrics badgeMetrics = libraryTabBadgeMetrics(
      layoutTier,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
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
            if (badgeCount != null)
              Positioned(
                top: badgeMetrics.top,
                right: badgeMetrics.right,
                child: _TabCountBadge(
                  count: badgeCount!,
                  metrics: badgeMetrics,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabCountBadge extends StatelessWidget {
  const _TabCountBadge({required this.count, required this.metrics});

  final int count;
  final LibraryTabBadgeMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(
        minWidth: metrics.minSize,
        minHeight: metrics.minSize,
      ),
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(metrics.borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: metrics.fontSize,
          fontWeight: FontWeight.w600,
          color: cs.onPrimary,
          height: 1.1,
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
      libraryActiveFilterSortIsCustomizedProvider,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: libraryToolbarActionSpacing(layoutTier),
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.listFilter,
          tooltip: '筛选与排序',
          semanticLabel: '打开筛选与排序',
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

class _LibraryOverflowMenuButton extends ConsumerStatefulWidget {
  const _LibraryOverflowMenuButton({
    this.layoutTier = LibraryLayoutTier.expanded,
  });

  final LibraryLayoutTier layoutTier;

  @override
  ConsumerState<_LibraryOverflowMenuButton> createState() =>
      _LibraryOverflowMenuButtonState();
}

class _LibraryPageSizeMenuButton extends ConsumerStatefulWidget {
  const _LibraryPageSizeMenuButton({
    this.layoutTier = LibraryLayoutTier.expanded,
  });

  final LibraryLayoutTier layoutTier;

  @override
  ConsumerState<_LibraryPageSizeMenuButton> createState() =>
      _LibraryPageSizeMenuButtonState();
}

class _LibraryPageSizeMenuButtonState
    extends ConsumerState<_LibraryPageSizeMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    final int activePageSize = ref.watch(libraryActivePageSizeProvider);
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -24,
      menuBuilder: () => _LibraryPageSizeMenu(
        layoutTier: widget.layoutTier,
        activePageSize: activePageSize,
        onSelected: (int pageSize) {
          _controller.hideMenu();
          ref
              .read(libraryTabPageSizeProvider.notifier)
              .setPageSize(displayTarget, pageSize);
        },
      ),
      child: GhostButton.icon(
        icon: LucideIcons.layoutGrid,
        tooltip: '每页数量',
        semanticLabel: '设置每页数量',
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.iconDefault,
        hoverColor: theme.hoverColor,
        overlayColor: theme.hoverColor,
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.toggleMenu(),
      ),
    );
  }
}

class _LibraryPageSizeMenu extends StatelessWidget {
  const _LibraryPageSizeMenu({
    required this.layoutTier,
    required this.activePageSize,
    required this.onSelected,
  });

  final LibraryLayoutTier layoutTier;
  final int activePageSize;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    return PopupMenuPanelShell(
      width: libraryPageSizeMenuWidth(layoutTier, viewportWidth),
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: kLibraryPageSizeOptions
              .map(
                (int pageSize) => _LibraryPageSizeMenuItem(
                  pageSize: pageSize,
                  isSelected: pageSize == activePageSize,
                  onTap: () => onSelected(pageSize),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _LibraryPageSizeMenuItem extends StatelessWidget {
  const _LibraryPageSizeMenuItem({
    required this.pageSize,
    required this.isSelected,
    required this.onTap,
  });

  final int pageSize;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? cs.primary.withAlpha(14) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isSelected ? Colors.transparent : cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            '$pageSize',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? cs.primary : cs.hentai.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryOverflowMenuButtonState
    extends ConsumerState<_LibraryOverflowMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -24,
      menuBuilder: () => _LibraryOverflowMenu(
        layoutTier: widget.layoutTier,
        onRefresh: () {
          _controller.hideMenu();
          ref.read(libraryRefreshActionProvider).call();
        },
        onScan: () {
          _controller.hideMenu();
        },
        onDeepScan: () {
          _controller.hideMenu();
        },
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: '更多操作',
        semanticLabel: '打开更多操作',
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.iconDefault,
        hoverColor: theme.hoverColor,
        overlayColor: theme.hoverColor,
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.toggleMenu(),
      ),
    );
  }
}

class _LibraryOverflowMenu extends StatelessWidget {
  const _LibraryOverflowMenu({
    required this.layoutTier,
    required this.onRefresh,
    required this.onScan,
    required this.onDeepScan,
  });

  final LibraryLayoutTier layoutTier;
  final VoidCallback onRefresh;
  final VoidCallback onScan;
  final VoidCallback onDeepScan;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    return PopupMenuPanelShell(
      width: libraryOverflowMenuWidth(layoutTier, viewportWidth),
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _LibraryOverflowMenuItem(
              icon: LucideIcons.rotateCw,
              label: '刷新',
              onTap: onRefresh,
            ),
            _LibraryOverflowMenuItem(
              icon: LucideIcons.scanSearch,
              label: '扫描',
              onTap: onScan,
            ),
            _LibraryOverflowMenuItem(
              icon: LucideIcons.scanLine,
              label: '深度扫描',
              onTap: onDeepScan,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryOverflowMenuItem extends StatelessWidget {
  const _LibraryOverflowMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: cs.hentai.iconDefault),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.hentai.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyLibraryToolbar extends ConsumerWidget {
  const _LegacyLibraryToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
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
            tooltip: '刷新',
            semanticLabel: '刷新',
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
