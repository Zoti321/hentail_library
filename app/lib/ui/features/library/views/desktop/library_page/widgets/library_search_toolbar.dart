part of 'library_page_widgets.dart';

class LibraryPageHeaderToolbar extends ConsumerWidget {
  const LibraryPageHeaderToolbar({
    super.key,
    this.onOpenFilterSort,
  });

  final VoidCallback? onOpenFilterSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showCountChips = libraryHeaderShowsCountChips(context);
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
                  child: LibraryPageHeader(showCountChips: showCountChips),
                ),
              ),
              if (onOpenFilterSort != null)
                _LibraryCompactToolbar(onOpenFilterSort: onOpenFilterSort!)
              else
                const _LegacyLibraryToolbar(),
            ],
          ),
          LibraryDisplayTargetTabs(showCountBadges: !showCountChips),
        ],
      ),
    );
  }
}

class LibraryContentSearchSliver extends ConsumerWidget {
  const LibraryContentSearchSliver({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        tokens.layout.contentHorizontalPadding,
        tokens.layout.contentVerticalPadding,
        tokens.layout.contentHorizontalPadding,
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
  const LibraryDisplayTargetTabs({super.key, this.showCountBadges = false});

  final bool showCountBadges;

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
          onTap: () => ref
              .read(libraryQueryIntentProvider.notifier)
              .setDisplayTarget(LibraryDisplayTarget.comics),
        ),
        const SizedBox(width: 24),
        _UnderlineTab(
          label: '系列',
          isSelected: displayTarget == LibraryDisplayTarget.series,
          badgeCount: showCountBadges ? seriesCount : null,
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
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
                top: -2,
                right: -10,
                child: _TabCountBadge(count: badgeCount!),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabCountBadge extends StatelessWidget {
  const _TabCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.onPrimary,
          height: 1.1,
        ),
      ),
    );
  }
}

class _LibraryCompactToolbar extends StatelessWidget {
  const _LibraryCompactToolbar({required this.onOpenFilterSort});

  final VoidCallback onOpenFilterSort;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.listFilter,
          tooltip: '筛选与排序',
          semanticLabel: '打开筛选与排序',
          iconSize: 16,
          size: 32,
          borderRadius: 8,
          foregroundColor: cs.hentai.iconDefault,
          hoverColor: theme.hoverColor,
          overlayColor: theme.hoverColor,
          delayTooltipThreeSeconds: true,
          onPressed: onOpenFilterSort,
        ),
        const _LibraryOverflowMenuButton(),
      ],
    );
  }
}

class _LibraryOverflowMenuButton extends ConsumerStatefulWidget {
  const _LibraryOverflowMenuButton();

  @override
  ConsumerState<_LibraryOverflowMenuButton> createState() =>
      _LibraryOverflowMenuButtonState();
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
    required this.onRefresh,
    required this.onScan,
    required this.onDeepScan,
  });

  final VoidCallback onRefresh;
  final VoidCallback onScan;
  final VoidCallback onDeepScan;

  @override
  Widget build(BuildContext context) {
    return PopupMenuPanelShell(
      width: 200,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
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
