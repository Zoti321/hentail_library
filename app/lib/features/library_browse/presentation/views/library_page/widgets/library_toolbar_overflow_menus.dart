part of 'library_page_widgets.dart';

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
    final int activePageSize = ref.watch(libraryActivePageSizeProvider);
    final AppLocalizations l10n = context.l10n;
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -32,
      menuBuilder: () => _LibraryPageSizeMenu(
        layoutTier: widget.layoutTier,
        activePageSize: activePageSize,
        onSelected: (int pageSize) {
          _controller.hideMenu();
          ref.read(libraryPageFacadeProvider.notifier).setPageSize(pageSize);
        },
      ),
      child: GhostButton.icon(
        icon: LucideIcons.layoutGrid,
        tooltip: l10n.libraryPageSizeTooltip,
        semanticLabel: l10n.libraryPageSizeSemantic,
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: context.hentai.iconDefault,
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
              color: isSelected ? cs.primary : context.hentai.textPrimary,
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
    final LibraryScanActivityState scanLeaf = ref.watch(
      libraryScanActivityStateProvider,
    );
    final bool scanning = scanLeaf.running;
    final AppLocalizations l10n = context.l10n;

    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -32,
      menuBuilder: () {
        if (scanning) {
          return _LibraryOverflowScanningMenu(
            layoutTier: widget.layoutTier,
            onCancel: () {
              _controller.hideMenu();
              ref.read(libraryScanCommandPortProvider).cancel();
            },
          );
        }
        final LibraryDisplayTarget displayTarget = ref.read(
          libraryDisplayTargetProvider,
        );
        return _LibraryOverflowMenu(
          layoutTier: widget.layoutTier,
          showSelectionEntry: displayTarget == LibraryDisplayTarget.comics,
          onRefresh: () {
            _controller.hideMenu();
            ref.read(libraryRefreshActionProvider).call();
          },
          onEnterSelection: () {
            _controller.hideMenu();
            ref.read(catalogSelectionProvider.notifier).enter();
          },
          onScan: () {
            _controller.hideMenu();
            ref.read(libraryScanCommandPortProvider).start(silent: true);
          },
          onDeepScan: () {
            _controller.hideMenu();
            ref
                .read(libraryScanCommandPortProvider)
                .start(mode: ScanMode.full, silent: true);
          },
        );
      },
      child: scanning
          ? Tooltip(
              message: scanLeaf.scanMode == ScanMode.full
                  ? l10n.libraryScanningDeep
                  : l10n.libraryScanning,
              child: Semantics(
                button: true,
                label: l10n.libraryCancelScan,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: theme.hoverColor,
                      overlayColor: WidgetStateProperty.all(theme.hoverColor),
                      onTap: () => _controller.toggleMenu(),
                      child: Center(
                        child: TerminalSpinner(
                          size: 16,
                          color: context.hentai.iconDefault,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : GhostButton.icon(
              icon: LucideIcons.ellipsisVertical,
              tooltip: l10n.libraryMoreActions,
              semanticLabel: l10n.libraryMoreActionsSemantic,
              iconSize: 16,
              size: 32,
              borderRadius: 8,
              foregroundColor: context.hentai.iconDefault,
              hoverColor: theme.hoverColor,
              overlayColor: theme.hoverColor,
              delayTooltipThreeSeconds: true,
              onPressed: () => _controller.toggleMenu(),
            ),
    );
  }
}

class _LibraryOverflowScanningMenu extends StatelessWidget {
  const _LibraryOverflowScanningMenu({
    required this.layoutTier,
    required this.onCancel,
  });

  final LibraryLayoutTier layoutTier;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
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
              icon: LucideIcons.x,
              label: l10n.libraryCancelScan,
              onTap: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryOverflowMenu extends StatelessWidget {
  const _LibraryOverflowMenu({
    required this.layoutTier,
    required this.showSelectionEntry,
    required this.onRefresh,
    required this.onScan,
    required this.onDeepScan,
    required this.onEnterSelection,
  });

  final LibraryLayoutTier layoutTier;
  final bool showSelectionEntry;
  final VoidCallback onRefresh;
  final VoidCallback onScan;
  final VoidCallback onDeepScan;
  final VoidCallback onEnterSelection;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
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
              label: l10n.libraryRefresh,
              onTap: onRefresh,
            ),
            if (showSelectionEntry)
              _LibraryOverflowMenuItem(
                icon: LucideIcons.squareCheck,
                label: l10n.catalogSelectionEnter,
                onTap: onEnterSelection,
              ),
            _LibraryOverflowMenuItem(
              icon: LucideIcons.scanSearch,
              label: l10n.libraryScan,
              onTap: onScan,
            ),
            _LibraryOverflowMenuItem(
              icon: LucideIcons.scanLine,
              label: l10n.libraryDeepScan,
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
              Icon(icon, size: 16, color: context.hentai.iconDefault),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.hentai.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
