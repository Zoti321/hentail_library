part of 'libraries_sidebar_section.dart';

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
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _SidebarChromeRow(
      isActive: false,
      expandProgress: expandProgress,
      labelOpacity: labelOpacity,
      leading: null,
      label: l10n.sidebarMoreLibraries,
      indentWithoutIcon: true,
      onTap: onTap,
      trailing: SizedBox(
        width: _kSidebarRowTrailingSlotSize,
        height: _kSidebarRowTrailingSlotSize,
        child: Center(
          child: Icon(
            expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
            size: 16,
            color: cs.hentai.textSecondary,
          ),
        ),
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
    this.nestedUnderMore = false,
    this.onNavigate,
  });

  final LocalLibrary library;
  final bool isActive;
  final double expandProgress;
  final double labelOpacity;
  final bool nestedUnderMore;
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
      extraLeftIndent: nestedUnderMore ? _kLibrariesMoreChildIndent : 0,
      onTap: () async {
        await ref
            .read(libraryManagementPortProvider)
            .openLibrary(context, library.libraryId);
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
              PopupMenuTextItem(
                label: l10n.sidebarAddLocalLibrary,
                onTap: () {
                  controller.hideMenu();
                  ref
                      .read(libraryManagementPortProvider)
                      .addLocalLibrary(context);
                },
              ),
              PopupMenuTextItem(
                label: l10n.sidebarAddRemoteLibrary,
                onTap: () {
                  controller.hideMenu();
                  ref
                      .read(libraryManagementPortProvider)
                      .addRemoteLibrary(context);
                },
              ),
              if (libraries.isNotEmpty)
                Divider(
                  height: tokens.spacing.sm,
                  color: cs.hentai.borderSubtle,
                ),
              ...libraries.map(
                (LocalLibrary library) => PopupMenuTextItem(
                  label: localLibraryDisplayName(library),
                  onTap: () async {
                    controller.hideMenu();
                    await ref
                        .read(libraryManagementPortProvider)
                        .openLibrary(context, library.libraryId);
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
    this.extraLeftIndent = 0,
  });

  final bool isActive;
  final double expandProgress;
  final double labelOpacity;
  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool indentWithoutIcon;
  final double extraLeftIndent;

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
    // Trailing actions are fixed-width (28+). Showing them while the rail is
    // still near collapsedWidth overflows the Row; gate on the same fade window
    // as labels (labelOpacity > 0 ⇒ expandProgress past the mid Interval).
    final bool showTrailing = trailing != null && labelOpacity > 0;

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
                left:
                    (indentWithoutIcon
                        ? tokens.spacing.md +
                              DesktopSidebar.navItemIconSize +
                              tokens.spacing.sm
                        : tokens.spacing.md * t) +
                    extraLeftIndent,
                right: tokens.spacing.xs,
              ),
              child: ClipRect(
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
                          softWrap: false,
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
                    if (showTrailing)
                      // Keep the row in hover while the pointer is on actions;
                      // action chrome uses a deeper fill so it stays distinct.
                      MouseRegion(
                        onEnter: (_) => hovered.value = true,
                        child: Opacity(opacity: labelOpacity, child: trailing!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
