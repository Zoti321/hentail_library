import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Komga-style Libraries section for [DesktopSidebar].
class LibrariesSidebarSection extends ConsumerWidget {
  const LibrariesSidebarSection({
    super.key,
    required this.expandProgress,
    required this.labelOpacity,
    required this.showCollapsedTooltip,
  });

  final double expandProgress;
  final double labelOpacity;
  final bool showCollapsedTooltip;

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

    if (collapsed) {
      return _CollapsedLibrariesButton(
        sectionActive: selection.sectionActive,
        libraryActive: selection.activeLibraryId != null,
        libraries: libraries,
        showCollapsedTooltip: showCollapsedTooltip,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LibrariesSectionHeader(
          isActive: selection.sectionActive,
          expandProgress: expandProgress,
          labelOpacity: labelOpacity,
          onTap: () => LibraryManagementActions.goAllLibraries(context),
        ),
        ...libraries.map(
          (LocalLibrary library) => _LibrarySidebarRow(
            library: library,
            isActive: selection.activeLibraryId == library.libraryId,
            expandProgress: expandProgress,
            labelOpacity: labelOpacity,
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
    required this.onTap,
  });

  final bool isActive;
  final double expandProgress;
  final double labelOpacity;
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
          _SectionAddMenuButton(),
          _SectionOverflowMenuButton(),
        ],
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
  });

  final LocalLibrary library;
  final bool isActive;
  final double expandProgress;
  final double labelOpacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SidebarChromeRow(
      isActive: isActive,
      expandProgress: expandProgress,
      labelOpacity: labelOpacity,
      leading: null,
      label: localLibraryDisplayName(library),
      indentWithoutIcon: true,
      onTap: () => LibraryManagementActions.openLibrary(
        ref,
        context,
        library.libraryId,
      ),
      trailing: _LibraryOverflowMenuButton(library: library),
    );
  }
}

class _CollapsedLibrariesButton extends ConsumerStatefulWidget {
  const _CollapsedLibrariesButton({
    required this.sectionActive,
    required this.libraryActive,
    required this.libraries,
    required this.showCollapsedTooltip,
  });

  final bool sectionActive;
  final bool libraryActive;
  final List<LocalLibrary> libraries;
  final bool showCollapsedTooltip;

  @override
  ConsumerState<_CollapsedLibrariesButton> createState() =>
      _CollapsedLibrariesButtonState();
}

class _CollapsedLibrariesButtonState
    extends ConsumerState<_CollapsedLibrariesButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final l10n = context.l10n;
    final Widget button = _SidebarIconOnlyButton(
      isActive: widget.sectionActive || widget.libraryActive,
      icon: LucideIcons.library,
      semanticLabel: l10n.libraryTitle,
      onTap: () => _controller.toggleMenu(),
    );

    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: 4,
      horizontalMargin: 8,
      menuBuilder: () => PopupMenuPanelShell(
        width: 220,
        blurRadius: 6,
        shadowOffset: const Offset(4, 0),
        borderRadius: context.tokens.radius.xs,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PopupMenuItem(
                label: l10n.sidebarAddLocalLibrary,
                onTap: () {
                  _controller.hideMenu();
                  LibraryManagementActions.addLocalLibrary(ref, context);
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarAddRemoteLibrary,
                onTap: () {
                  _controller.hideMenu();
                  LibraryManagementActions.addRemoteLibrary(ref, context);
                },
              ),
              if (widget.libraries.isNotEmpty)
                Divider(height: 8, color: cs.hentai.borderSubtle),
              ...widget.libraries.map(
                (LocalLibrary library) => _PopupMenuItem(
                  label: localLibraryDisplayName(library),
                  onTap: () {
                    _controller.hideMenu();
                    LibraryManagementActions.openLibrary(
                      ref,
                      context,
                      library.libraryId,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      child: widget.showCollapsedTooltip
          ? Tooltip(
              message: l10n.libraryTitle,
              waitDuration: const Duration(seconds: 1),
              child: button,
            )
          : button,
    );
  }
}

class _SectionAddMenuButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SectionAddMenuButton> createState() =>
      _SectionAddMenuButtonState();
}

class _SectionAddMenuButtonState extends ConsumerState<_SectionAddMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -4,
      menuBuilder: () => PopupMenuPanelShell(
        width: 180,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        borderRadius: context.tokens.radius.xs,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PopupMenuItem(
                label: l10n.sidebarAddLocalLibrary,
                onTap: () {
                  _controller.hideMenu();
                  LibraryManagementActions.addLocalLibrary(ref, context);
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarAddRemoteLibrary,
                onTap: () {
                  _controller.hideMenu();
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
        borderRadius: 6,
        foregroundColor: cs.hentai.textSecondary,
        hoverColor: cs.hentai.sidebarItemHoverBackground,
        overlayColor: cs.hentai.sidebarItemHoverBackground.withAlpha(110),
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.toggleMenu(),
      ),
    );
  }
}

class _SectionOverflowMenuButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SectionOverflowMenuButton> createState() =>
      _SectionOverflowMenuButtonState();
}

class _SectionOverflowMenuButtonState
    extends ConsumerState<_SectionOverflowMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -4,
      menuBuilder: () => PopupMenuPanelShell(
        width: 200,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        borderRadius: context.tokens.radius.xs,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PopupMenuItem(
                label: l10n.sidebarReorderLibrariesLater,
                enabled: false,
                onTap: () {},
              ),
              _PopupMenuItem(
                label: l10n.sidebarScanAllLibraries,
                onTap: () {
                  _controller.hideMenu();
                  LibraryManagementActions.scanAllLibraries(ref);
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarDeepScanAllLibraries,
                onTap: () {
                  _controller.hideMenu();
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
        borderRadius: 6,
        foregroundColor: cs.hentai.textSecondary,
        hoverColor: cs.hentai.sidebarItemHoverBackground,
        overlayColor: cs.hentai.sidebarItemHoverBackground.withAlpha(110),
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.toggleMenu(),
      ),
    );
  }
}

class _LibraryOverflowMenuButton extends ConsumerStatefulWidget {
  const _LibraryOverflowMenuButton({required this.library});

  final LocalLibrary library;

  @override
  ConsumerState<_LibraryOverflowMenuButton> createState() =>
      _LibraryOverflowMenuButtonState();
}

class _LibraryOverflowMenuButtonState
    extends ConsumerState<_LibraryOverflowMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool remote = isRemoteLibrary(widget.library);
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -4,
      menuBuilder: () => PopupMenuPanelShell(
        width: 200,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        borderRadius: context.tokens.radius.xs,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PopupMenuItem(
                label: l10n.sidebarScanLibrary,
                onTap: () {
                  _controller.hideMenu();
                  LibraryManagementActions.scanLibrary(
                    ref,
                    context,
                    widget.library.libraryId,
                  );
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarDeepScanLibrary,
                onTap: () {
                  _controller.hideMenu();
                  LibraryManagementActions.scanLibrary(
                    ref,
                    context,
                    widget.library.libraryId,
                    mode: ScanMode.full,
                  );
                },
              ),
              _PopupMenuItem(
                label: l10n.sidebarRefreshMetadataLater,
                enabled: false,
                onTap: () {},
              ),
              if (remote)
                _PopupMenuItem(
                  label: l10n.sidebarEditLibrary,
                  onTap: () {
                    _controller.hideMenu();
                    LibraryManagementActions.editRemoteLibrary(
                      ref,
                      context,
                      widget.library,
                    );
                  },
                ),
              _PopupMenuItem(
                label: l10n.sidebarDeleteLibrary,
                onTap: () {
                  _controller.hideMenu();
                  LibraryManagementActions.deleteLibrary(
                    ref,
                    context,
                    widget.library,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: localLibraryDisplayName(widget.library),
        semanticLabel: localLibraryDisplayName(widget.library),
        iconSize: 14,
        size: 28,
        borderRadius: 6,
        foregroundColor: cs.hentai.textSecondary,
        hoverColor: cs.hentai.sidebarItemHoverBackground,
        overlayColor: cs.hentai.sidebarItemHoverBackground.withAlpha(110),
        delayTooltipThreeSeconds: true,
        onPressed: () => _controller.toggleMenu(),
      ),
    );
  }
}

class _PopupMenuItem extends StatelessWidget {
  const _PopupMenuItem({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: enabled ? cs.hentai.textPrimary : cs.hentai.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _SidebarIconOnlyButton extends StatefulWidget {
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
  State<_SidebarIconOnlyButton> createState() => _SidebarIconOnlyButtonState();
}

class _SidebarIconOnlyButtonState extends State<_SidebarIconOnlyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color background = widget.isActive
        ? cs.hentai.sidebarItemActiveBackground
        : (_hovered ? cs.hentai.sidebarItemHoverBackground : cs.hentai.sidebarBackground);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: widget.semanticLabel,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Align(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: widget.isActive ? 1 : 0.8,
                    color: widget.isActive
                        ? cs.hentai.sidebarItemActiveBorder
                        : cs.hentai.sidebarBackground,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive || _hovered
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

class _SidebarChromeRow extends StatefulWidget {
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
  State<_SidebarChromeRow> createState() => _SidebarChromeRowState();
}

class _SidebarChromeRowState extends State<_SidebarChromeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final double t = widget.expandProgress.clamp(0.0, 1.0);
    final Color background = widget.isActive
        ? cs.hentai.sidebarItemActiveBackground
        : (_hovered ? cs.hentai.sidebarItemHoverBackground : cs.hentai.sidebarBackground);
    final Color textColor = widget.isActive || _hovered
        ? cs.hentai.textPrimary
        : cs.hentai.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: widget.label,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  width: widget.isActive ? 1 : 0.8,
                  color: widget.isActive
                      ? cs.hentai.sidebarItemActiveBorder
                      : cs.hentai.sidebarBackground,
                ),
              ),
              padding: EdgeInsets.only(
                left: widget.indentWithoutIcon ? 12 + 18 + 8 : 12 * t,
                right: 4,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                children: <Widget>[
                  if (widget.leading != null)
                    IconTheme(
                      data: IconThemeData(color: textColor, size: 18),
                      child: widget.leading!,
                    ),
                  if (widget.leading != null) const SizedBox(width: 8),
                  Expanded(
                    child: Opacity(
                      opacity: widget.labelOpacity,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
