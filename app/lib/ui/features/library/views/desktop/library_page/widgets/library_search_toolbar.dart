part of 'library_page_widgets.dart';

class LibrarySearchToolbarRow extends ConsumerStatefulWidget {
  const LibrarySearchToolbarRow({
    super.key,
    this.initialQuery = '',
    this.onOpenFilterSort,
  });

  final String initialQuery;
  final VoidCallback? onOpenFilterSort;

  @override
  ConsumerState<LibrarySearchToolbarRow> createState() =>
      _LibrarySearchToolbarRowState();
}

class _LibrarySearchToolbarRowState
    extends ConsumerState<LibrarySearchToolbarRow> {
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
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.25,
              ),
              child: CustomTextField(
                controller: _controller,
                hintText: '搜索…',
                onSubmitted: _handleSubmitSearch,
              ),
            ),
          ),
        ),
        const Expanded(child: Center(child: LibraryDisplayTargetTabs())),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: widget.onOpenFilterSort != null
                ? _LibraryCompactToolbar(
                    onOpenFilterSort: widget.onOpenFilterSort!,
                  )
                : const _LegacyLibraryToolbar(),
          ),
        ),
      ],
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
  const LibraryDisplayTargetTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _UnderlineTab(
          label: '漫画',
          isSelected: displayTarget == LibraryDisplayTarget.comics,
          onTap: () => ref
              .read(libraryQueryIntentProvider.notifier)
              .setDisplayTarget(LibraryDisplayTarget.comics),
        ),
        const SizedBox(width: 24),
        _UnderlineTab(
          label: '系列',
          isSelected: displayTarget == LibraryDisplayTarget.series,
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
