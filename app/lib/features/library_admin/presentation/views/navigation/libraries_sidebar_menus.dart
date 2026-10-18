part of 'libraries_sidebar_section.dart';

class _SectionAddMenuButton extends HookConsumerWidget {
  const _SectionAddMenuButton();

  static const double _kMenuMaxWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final CustomPopupMenuController controller = useMemoized(
      CustomPopupMenuController.new,
    );

    return CustomPopupMenu(
      controller: controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -tokens.spacing.xs,
      menuBuilder: () => PopupMenuPanelShell(
        maxWidth: _kMenuMaxWidth,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        borderRadius: tokens.radius.xs,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PopupMenuItem(
                label: l10n.sidebarAddLocalLibrary,
                onTap: () {
                  controller.hideMenu();
                  ref
                      .read(libraryManagementPortProvider)
                      .addLocalLibrary(context);
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarAddRemoteLibrary,
                onTap: () {
                  controller.hideMenu();
                  ref
                      .read(libraryManagementPortProvider)
                      .addRemoteLibrary(context);
                },
              ),
            ],
          ),
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.plus,
        tooltip: l10n.sidebarAddLibraryTooltip,
        semanticLabel: l10n.sidebarAddLibraryTooltip,
        iconSize: 14,
        size: 28,
        borderRadius: tokens.radius.sm,
        foregroundColor: cs.hentai.textSecondary,
        hoverColor: _sidebarActionHoverBackground(cs.hentai),
        overlayColor: _sidebarActionHoverBackground(cs.hentai).withAlpha(110),
        delayTooltipThreeSeconds: true,
        onPressed: controller.toggleMenu,
      ),
    );
  }
}

class _SectionOverflowMenuButton extends HookConsumerWidget {
  const _SectionOverflowMenuButton({required this.reorderEnabled});

  final bool reorderEnabled;

  static const double _kMenuMaxWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final CustomPopupMenuController controller = useMemoized(
      CustomPopupMenuController.new,
    );

    return CustomPopupMenu(
      controller: controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -tokens.spacing.xs,
      menuBuilder: () => PopupMenuPanelShell(
        maxWidth: _kMenuMaxWidth,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        borderRadius: tokens.radius.xs,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PopupMenuItem(
                label: l10n.sidebarReorderLibraries,
                enabled: reorderEnabled,
                onTap: () {
                  controller.hideMenu();
                  ref.read(libraryReorderModeProvider.notifier).enter();
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarScanAllLibraries,
                onTap: () {
                  controller.hideMenu();
                  ref.read(libraryManagementPortProvider).scanAllLibraries();
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarDeepScanAllLibraries,
                onTap: () {
                  controller.hideMenu();
                  ref
                      .read(libraryManagementPortProvider)
                      .scanAllLibraries(mode: ScanMode.full);
                },
              ),
            ],
          ),
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: l10n.libraryTitle,
        semanticLabel: l10n.libraryTitle,
        iconSize: 14,
        size: 28,
        borderRadius: tokens.radius.sm,
        foregroundColor: cs.hentai.textSecondary,
        hoverColor: _sidebarActionHoverBackground(cs.hentai),
        overlayColor: _sidebarActionHoverBackground(cs.hentai).withAlpha(110),
        delayTooltipThreeSeconds: true,
        onPressed: controller.toggleMenu,
      ),
    );
  }
}

class _LibraryOverflowMenuButton extends HookConsumerWidget {
  const _LibraryOverflowMenuButton({required this.library});

  final LocalLibrary library;

  static const double _kMenuMaxWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final CustomPopupMenuController controller = useMemoized(
      CustomPopupMenuController.new,
    );
    final List<LibrarySidebarOverflowAction> actions =
        librarySidebarOverflowActions(library);
    final MetadataRefreshState refreshState = ref.watch(
      metadataRefreshControllerProvider,
    );
    final bool scanning = ref.watch(
      scanLibraryControllerProvider.select((s) => s.running),
    );
    final bool refreshingThis = ref
        .read(metadataRefreshControllerProvider.notifier)
        .isRefreshingLibrary(library.libraryId);
    final bool otherWriteBusy =
        scanning || (refreshState.running && !refreshingThis);

    return CustomPopupMenu(
      controller: controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -tokens.spacing.xs,
      menuBuilder: () => PopupMenuPanelShell(
        maxWidth: _kMenuMaxWidth,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        borderRadius: tokens.radius.xs,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final LibrarySidebarOverflowAction action in actions)
                _PopupMenuItem(
                  label: _labelFor(
                    l10n,
                    action,
                    refreshingThis: refreshingThis,
                  ),
                  enabled:
                      action == LibrarySidebarOverflowAction.refreshMetadata
                      ? !otherWriteBusy
                      : true,
                  isDestructive: action == LibrarySidebarOverflowAction.delete,
                  onTap: () {
                    controller.hideMenu();
                    _handleAction(ref, context, action, refreshingThis);
                  },
                ),
            ],
          ),
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: localLibraryDisplayName(library),
        semanticLabel: localLibraryDisplayName(library),
        iconSize: 14,
        size: 28,
        borderRadius: tokens.radius.sm,
        foregroundColor: cs.hentai.textSecondary,
        hoverColor: _sidebarActionHoverBackground(cs.hentai),
        overlayColor: _sidebarActionHoverBackground(cs.hentai).withAlpha(110),
        delayTooltipThreeSeconds: true,
        onPressed: controller.toggleMenu,
      ),
    );
  }

  String _labelFor(
    AppLocalizations l10n,
    LibrarySidebarOverflowAction action, {
    required bool refreshingThis,
  }) {
    return switch (action) {
      LibrarySidebarOverflowAction.scan => l10n.sidebarScanLibrary,
      LibrarySidebarOverflowAction.deepScan => l10n.sidebarDeepScanLibrary,
      LibrarySidebarOverflowAction.refreshMetadata =>
        refreshingThis ? l10n.cancelRefreshMetadata : l10n.refreshMetadata,
      LibrarySidebarOverflowAction.edit => l10n.sidebarEditLibrary,
      LibrarySidebarOverflowAction.delete => l10n.sidebarDeleteLibrary,
    };
  }

  void _handleAction(
    WidgetRef ref,
    BuildContext context,
    LibrarySidebarOverflowAction action,
    bool refreshingThis,
  ) {
    switch (action) {
      case LibrarySidebarOverflowAction.scan:
        ref
            .read(libraryManagementPortProvider)
            .scanLibrary(context, library.libraryId);
      case LibrarySidebarOverflowAction.deepScan:
        ref
            .read(libraryManagementPortProvider)
            .scanLibrary(context, library.libraryId, mode: ScanMode.full);
      case LibrarySidebarOverflowAction.refreshMetadata:
        if (refreshingThis) {
          ref.read(metadataRefreshControllerProvider.notifier).cancel();
          return;
        }
        _refreshLibraryMetadata(ref, context);
      case LibrarySidebarOverflowAction.edit:
        ref
            .read(libraryManagementPortProvider)
            .editLibrarySettings(context, library);
      case LibrarySidebarOverflowAction.delete:
        ref.read(libraryManagementPortProvider).deleteLibrary(context, library);
    }
  }

  Future<void> _refreshLibraryMetadata(
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final result = await ref
          .read(metadataRefreshControllerProvider.notifier)
          .refreshLibrary(
            libraryId: library.libraryId,
            name: localLibraryDisplayName(library),
          );
      if (!context.mounted) {
        return;
      }
      showMetadataRefreshBatchToast(context, result);
    } catch (err) {
      if (!context.mounted) {
        return;
      }
      showErrorToast(context, err);
    }
  }
}

class _PopupMenuItem extends HookWidget {
  const _PopupMenuItem({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final HentaiColorScheme h = cs.hentai;
    final ValueNotifier<bool> hovered = useState(false);

    // Idle must be opaque (panel surface). Lerping from Colors.transparent
    // goes through muddy greys and looks like a broken color animation.
    final Color idleBackground = cs.surface;
    // Light danger wash (not solid red) so hover stays readable.
    final Color dangerHover = Color.lerp(
      idleBackground,
      h.contextMenuDanger,
      0.2,
    )!;

    final Color background;
    final Color foreground;
    if (!enabled) {
      background = idleBackground;
      foreground = h.textTertiary;
    } else if (hovered.value) {
      background = isDestructive ? dangerHover : h.contextMenuHover;
      foreground = isDestructive ? h.contextMenuDanger : h.textPrimary;
    } else {
      background = idleBackground;
      foreground = h.textPrimary;
    }

    // copyWith keeps ThemeData.fontFamily (MI_Sans_Regular); a bare TextStyle
    // under AnimatedDefaultTextStyle would fall back to the platform font.
    final TextStyle labelStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          fontSize: tokens.text.bodySm,
          color: foreground,
        );

    return MouseRegion(
      onEnter: enabled ? (_) => hovered.value = true : null,
      onExit: enabled ? (_) => hovered.value = false : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          color: background,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            style: labelStyle,
            child: Text(label, textAlign: TextAlign.start),
          ),
        ),
      ),
    );
  }
}
