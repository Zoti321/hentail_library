import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/library_sidebar_layout.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/core/widgets/navigation/desktop_sidebar.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_sidebar_overflow_actions.dart';
import 'package:hentai_library/ui/features/shell/state/metadata_refresh_toasts.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Row hover: lighter than the shared sidebar token so action buttons can
/// sit on a deeper chrome without blending in.
Color _sidebarRowHoverBackground(HentaiColorScheme h) =>
    Color.lerp(h.sidebarBackground, h.sidebarItemHoverBackground, 0.55)!;

/// Trailing +/-/⋯ button hover: darker than the row hover for contrast.
Color _sidebarActionHoverBackground(HentaiColorScheme h) =>
    Color.lerp(h.sidebarItemHoverBackground, h.borderStrong, 0.5)!;

/// Komga-style Libraries section for the desktop sidebar (injected by shell).
class LibrariesSidebarSection extends HookConsumerWidget {
  const LibrariesSidebarSection({
    super.key,
    required this.expandProgress,
    required this.labelOpacity,
    required this.showCollapsedTooltip,
    this.allowLibraryReorder = true,
    this.onNavigate,
  });

  final double expandProgress;
  final double labelOpacity;
  final bool showCollapsedTooltip;
  final bool allowLibraryReorder;

  /// Called before route changes (e.g. close the compact navigation drawer).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CurrentLibraryState? state = ref
        .watch(currentLibraryProvider)
        .asData
        ?.value;
    final List<LocalLibrary> libraries =
        state?.libraries ?? const <LocalLibrary>[];
    final String path = GoRouterState.of(context).uri.path;
    final LibrariesSidebarSelection selection = librariesSidebarSelection(
      path: path,
      currentLibraryId: state?.currentId,
    );
    final bool collapsed = expandProgress < 0.05;
    final LibrarySidebarSections sections = splitLibrarySidebar(libraries);
    final String? currentId = state?.currentId;
    final bool currentIsUnpinned =
        currentId != null &&
        sections.unpinned.any(
          (LocalLibrary library) => library.libraryId == currentId,
        );
    final ValueNotifier<bool> moreExpanded = useState(false);
    final ObjectRef<String?> autoOpenedFor = useRef<String?>(null);
    useEffect(() {
      if (currentIsUnpinned && autoOpenedFor.value != currentId) {
        moreExpanded.value = true;
        autoOpenedFor.value = currentId;
      }
      return null;
    }, <Object?>[currentId, currentIsUnpinned]);

    if (collapsed) {
      return _CollapsedLibrariesButton(
        isActive: librariesRailIconActive(selection),
        libraries: libraries,
        showCollapsedTooltip: showCollapsedTooltip,
        onNavigate: onNavigate,
      );
    }

    final bool showMore = showLibrariesMore(sections.unpinned);
    final bool reorderEnabled =
        allowLibraryReorder && librariesReorderMenuEnabled(libraries.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LibrariesSectionHeader(
          isActive: selection.sectionActive,
          expandProgress: expandProgress,
          labelOpacity: labelOpacity,
          reorderEnabled: reorderEnabled,
          onTap: () {
            LibraryManagementActions.goAllLibraries(context);
            onNavigate?.call();
          },
        ),
        ...sections.pinned.map(
          (LocalLibrary library) => _LibrarySidebarRow(
            library: library,
            isActive: selection.activeLibraryId == library.libraryId,
            expandProgress: expandProgress,
            labelOpacity: labelOpacity,
            onNavigate: onNavigate,
          ),
        ),
        if (showMore)
          _LibrariesMoreRow(
            expanded: moreExpanded.value,
            expandProgress: expandProgress,
            labelOpacity: labelOpacity,
            onTap: () => moreExpanded.value = !moreExpanded.value,
          ),
        if (showMore && moreExpanded.value)
          ...sections.unpinned.map(
            (LocalLibrary library) => _LibrarySidebarRow(
              library: library,
              isActive: selection.activeLibraryId == library.libraryId,
              expandProgress: expandProgress,
              labelOpacity: labelOpacity,
              onNavigate: onNavigate,
            ),
          ),
      ],
    );
  }
}

class _LibrariesSectionHeader extends StatelessWidget {
  const _LibrariesSectionHeader({
    required this.isActive,
    required this.expandProgress,
    required this.labelOpacity,
    required this.reorderEnabled,
    required this.onTap,
  });

  final bool isActive;
  final double expandProgress;
  final double labelOpacity;
  final bool reorderEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SidebarChromeRow(
      isActive: isActive,
      expandProgress: expandProgress,
      labelOpacity: labelOpacity,
      leading: const Icon(LucideIcons.library, size: 18),
      label: l10n.libraryTitle,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _SectionAddMenuButton(),
          _SectionOverflowMenuButton(reorderEnabled: reorderEnabled),
        ],
      ),
    );
  }
}

class _LibrariesMoreRow extends StatelessWidget {
  const _LibrariesMoreRow({
    required this.expanded,
    required this.expandProgress,
    required this.labelOpacity,
    required this.onTap,
  });

  final bool expanded;
  final double expandProgress;
  final double labelOpacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SidebarChromeRow(
      isActive: false,
      expandProgress: expandProgress,
      labelOpacity: labelOpacity,
      leading: null,
      label: l10n.sidebarMoreLibraries,
      indentWithoutIcon: true,
      onTap: onTap,
      trailing: Icon(
        expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
        size: 16,
      ),
    );
  }
}

class _LibrarySidebarRow extends ConsumerWidget {
  const _LibrarySidebarRow({
    required this.library,
    required this.isActive,
    required this.expandProgress,
    required this.labelOpacity,
    this.onNavigate,
  });

  final LocalLibrary library;
  final bool isActive;
  final double expandProgress;
  final double labelOpacity;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SidebarChromeRow(
      isActive: isActive,
      expandProgress: expandProgress,
      labelOpacity: labelOpacity,
      leading: null,
      label: localLibraryDisplayName(library),
      indentWithoutIcon: true,
      onTap: () async {
        await LibraryManagementActions.openLibrary(
          ref,
          context,
          library.libraryId,
        );
        onNavigate?.call();
      },
      trailing: _LibraryOverflowMenuButton(library: library),
    );
  }
}

class _CollapsedLibrariesButton extends HookConsumerWidget {
  const _CollapsedLibrariesButton({
    required this.isActive,
    required this.libraries,
    required this.showCollapsedTooltip,
    this.onNavigate,
  });

  final bool isActive;
  final List<LocalLibrary> libraries;
  final bool showCollapsedTooltip;
  final VoidCallback? onNavigate;

  static const double _kMenuMaxWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final CustomPopupMenuController controller = useMemoized(
      CustomPopupMenuController.new,
    );

    final Widget button = _SidebarIconOnlyButton(
      isActive: isActive,
      icon: LucideIcons.library,
      semanticLabel: l10n.libraryTitle,
      onTap: controller.toggleMenu,
    );

    return CustomPopupMenu(
      controller: controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: tokens.spacing.xs,
      horizontalMargin: tokens.spacing.sm,
      menuBuilder: () => PopupMenuPanelShell(
        maxWidth: _kMenuMaxWidth,
        blurRadius: 6,
        shadowOffset: const Offset(4, 0),
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
                  LibraryManagementActions.addLocalLibrary(ref, context);
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarAddRemoteLibrary,
                onTap: () {
                  controller.hideMenu();
                  LibraryManagementActions.addRemoteLibrary(ref, context);
                },
              ),
              if (libraries.isNotEmpty)
                Divider(
                  height: tokens.spacing.sm,
                  color: cs.hentai.borderSubtle,
                ),
              ...libraries.map(
                (LocalLibrary library) => _PopupMenuItem(
                  label: localLibraryDisplayName(library),
                  onTap: () async {
                    controller.hideMenu();
                    await LibraryManagementActions.openLibrary(
                      ref,
                      context,
                      library.libraryId,
                    );
                    onNavigate?.call();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      child: showCollapsedTooltip
          ? Tooltip(
              message: l10n.libraryTitle,
              waitDuration: const Duration(seconds: 1),
              child: button,
            )
          : button,
    );
  }
}

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
                  LibraryManagementActions.addLocalLibrary(ref, context);
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarAddRemoteLibrary,
                onTap: () {
                  controller.hideMenu();
                  LibraryManagementActions.addRemoteLibrary(ref, context);
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
                  LibraryManagementActions.scanAllLibraries(ref);
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarDeepScanAllLibraries,
                onTap: () {
                  controller.hideMenu();
                  LibraryManagementActions.scanAllLibraries(
                    ref,
                    mode: ScanMode.full,
                  );
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
    final bool scanning = ref.watch(scanLibraryControllerProvider).running;
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
        LibraryManagementActions.scanLibrary(ref, context, library.libraryId);
      case LibrarySidebarOverflowAction.deepScan:
        LibraryManagementActions.scanLibrary(
          ref,
          context,
          library.libraryId,
          mode: ScanMode.full,
        );
      case LibrarySidebarOverflowAction.refreshMetadata:
        if (refreshingThis) {
          ref.read(metadataRefreshControllerProvider.notifier).cancel();
          return;
        }
        _refreshLibraryMetadata(ref, context);
      case LibrarySidebarOverflowAction.edit:
        LibraryManagementActions.editLibrarySettings(ref, context, library);
      case LibrarySidebarOverflowAction.delete:
        LibraryManagementActions.deleteLibrary(ref, context, library);
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

class _SidebarIconOnlyButton extends HookWidget {
  const _SidebarIconOnlyButton({
    required this.isActive,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool isActive;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ValueNotifier<bool> hovered = useState(false);
    final Color background = isActive
        ? cs.hentai.sidebarItemActiveBackground
        : (hovered.value
              ? cs.hentai.sidebarItemHoverBackground
              : cs.hentai.sidebarBackground);

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: DesktopSidebar.navItemVerticalMargin,
      ),
      child: MouseRegion(
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: GestureDetector(
            onTap: onTap,
            child: Align(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: DesktopSidebar.navItemHeight,
                height: DesktopSidebar.navItemHeight,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(tokens.radius.md),
                  border: Border.all(
                    width: 1,
                    color: isActive
                        ? cs.hentai.sidebarItemActiveBorder
                        : cs.hentai.sidebarBackground,
                  ),
                ),
                child: Icon(
                  icon,
                  size: DesktopSidebar.navItemIconSize,
                  color: isActive || hovered.value
                      ? cs.hentai.textPrimary
                      : cs.hentai.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarChromeRow extends HookWidget {
  const _SidebarChromeRow({
    required this.isActive,
    required this.expandProgress,
    required this.labelOpacity,
    required this.label,
    required this.onTap,
    this.leading,
    this.trailing,
    this.indentWithoutIcon = false,
  });

  final bool isActive;
  final double expandProgress;
  final double labelOpacity;
  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool indentWithoutIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final HentaiColorScheme h = cs.hentai;
    final AppThemeTokens tokens = context.tokens;
    final ValueNotifier<bool> hovered = useState(false);
    final double t = expandProgress.clamp(0.0, 1.0);
    final Color rowHover = _sidebarRowHoverBackground(h);
    final Color background = isActive
        ? (hovered.value
              ? Color.lerp(h.sidebarItemActiveBackground, rowHover, 0.4)!
              : h.sidebarItemActiveBackground)
        : (hovered.value ? rowHover : h.sidebarBackground);
    final Color textColor = isActive || hovered.value
        ? h.textPrimary
        : h.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: DesktopSidebar.navItemVerticalMargin,
      ),
      child: MouseRegion(
        onEnter: (_) => hovered.value = true,
        onExit: (_) => hovered.value = false,
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: DesktopSidebar.navItemHeight,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(tokens.radius.md),
                // Constant border width avoids vertical jump on selection.
                border: Border.all(
                  width: 1,
                  color: isActive
                      ? h.sidebarItemActiveBorder
                      : h.sidebarBackground,
                ),
              ),
              padding: EdgeInsets.only(
                left: indentWithoutIcon
                    ? tokens.spacing.md +
                          DesktopSidebar.navItemIconSize +
                          tokens.spacing.sm
                    : tokens.spacing.md * t,
                right: tokens.spacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (leading != null)
                    IconTheme(
                      data: IconThemeData(
                        color: textColor,
                        size: DesktopSidebar.navItemIconSize,
                      ),
                      child: leading!,
                    ),
                  if (leading != null) SizedBox(width: tokens.spacing.sm),
                  Expanded(
                    child: Opacity(
                      opacity: labelOpacity,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        strutStyle: const StrutStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          forceStrutHeight: true,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontSize: tokens.text.bodyMd,
                          height: 1.2,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null)
                    // Keep the row in hover while the pointer is on actions;
                    // action chrome uses a deeper fill so it stays distinct.
                    MouseRegion(
                      onEnter: (_) => hovered.value = true,
                      child: trailing!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
