import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/dto/nav_item_data.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/app_navigation.dart';
import 'package:hentai_library/ui/features/shell/state/library_reorder_mode.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Builds the Libraries section inserted after Home in [DesktopSidebar].
typedef DesktopSidebarLibrariesSectionBuilder =
    Widget Function({
      required double expandProgress,
      required double labelOpacity,
      required bool showCollapsedTooltip,
    });

class DesktopSidebar extends HookConsumerWidget {
  static const double expandedWidth = 256;
  static const double collapsedWidth = 72;

  /// Painted height of every sidebar nav chrome (main + libraries), border included.
  /// Idle/hover/active/disabled must all keep this height to avoid layout shift.
  static const double navItemHeight = 36;

  /// Vertical gap outside each nav chrome (top and bottom).
  static const double navItemVerticalMargin = 4;

  static const double navItemIconSize = 18;
  static const Duration _kAnimDuration = Duration(milliseconds: 220);
  static const Curve _kAnimCurve = Curves.easeOutCubic;

  /// Collapse: fade out in first half; expand: fade in during second half.
  static const Interval _kLabelOpacityInterval = Interval(
    0.5,
    1.0,
    curve: Curves.easeOutCubic,
  );

  final String activeId;
  final bool isExpanded;
  final bool showCollapseToggle;
  final bool applyDrawerTopInset;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onDestinationSelected;
  final DesktopSidebarLibrariesSectionBuilder? librariesSectionBuilder;

  /// When non-null and reorder mode is on, replaces main nav + system items.
  final WidgetBuilder? librariesReorderPaneBuilder;

  /// Compact / collapsed rail cannot enter Library reorder mode.
  final bool allowLibraryReorder;

  const DesktopSidebar({
    super.key,
    required this.activeId,
    required this.isExpanded,
    this.showCollapseToggle = true,
    this.applyDrawerTopInset = false,
    required this.onToggleExpanded,
    required this.onDestinationSelected,
    this.librariesSectionBuilder,
    this.librariesReorderPaneBuilder,
    this.allowLibraryReorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double topPadding = applyDrawerTopInset
        ? MediaQuery.viewPaddingOf(context).top + tokens.spacing.lg
        : 0;
    final double bottomPadding =
        MediaQuery.viewPaddingOf(context).bottom + tokens.spacing.lg;

    final AnimationController expandController = useAnimationController(
      duration: _kAnimDuration,
      initialValue: isExpanded ? 1.0 : 0.0,
    );

    useEffect(() {
      if (isExpanded) {
        expandController.forward();
      } else {
        expandController.reverse();
      }
      return null;
    }, <Object?>[isExpanded]);

    useEffect(() {
      if (!isExpanded || !allowLibraryReorder) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(libraryReorderModeProvider.notifier).exit();
        });
      }
      return null;
    }, <Object?>[isExpanded, allowLibraryReorder]);

    final l10n = context.l10n;
    final bool reorderMode = ref.watch(libraryReorderModeProvider);
    final List<NavItemData> menuItems = AppNavigation.desktopMainNavItems(l10n);
    final List<NavItemData> systemItems = AppNavigation.desktopSystemNavItems(
      l10n,
    );

    return AnimatedBuilder(
      animation: expandController,
      builder: (BuildContext context, Widget? child) {
        final double t = expandController.value;
        final double curvedT = _kAnimCurve.transform(t);
        final double width =
            collapsedWidth + (expandedWidth - collapsedWidth) * curvedT;
        final double labelOpacity = _kLabelOpacityInterval.transform(t);
        final Alignment toggleAlignment = Alignment.lerp(
          Alignment.center,
          Alignment.centerLeft,
          curvedT,
        )!;
        final bool showCollapsedTooltip =
            expandController.status == AnimationStatus.dismissed;

        final List<Widget> mainNav = <Widget>[];
        for (final NavItemData item in menuItems) {
          mainNav.add(
            _SidebarButton(
              item: item,
              isActive: activeId == item.id,
              expandProgress: curvedT,
              labelOpacity: labelOpacity,
              showCollapsedTooltip: showCollapsedTooltip,
              onTap: () => onDestinationSelected(item.id),
            ),
          );
          if (item.id == AppNavigation.navIdHome) {
            final DesktopSidebarLibrariesSectionBuilder? builder =
                librariesSectionBuilder;
            if (builder != null) {
              mainNav.add(
                builder(
                  expandProgress: curvedT,
                  labelOpacity: labelOpacity,
                  showCollapsedTooltip: showCollapsedTooltip,
                ),
              );
            }
          }
        }

        return Container(
          width: width,
          height: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: cs.hentai.sidebarBackground,
            border: Border(right: BorderSide(color: cs.hentai.borderSubtle)),
          ),
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.sm,
            topPadding,
            tokens.spacing.sm,
            bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showCollapseToggle) ...<Widget>[
                Align(
                  alignment: toggleAlignment,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
                    child: GhostButton.icon(
                      icon: LucideIcons.menu,
                      tooltip: '',
                      semanticLabel: isExpanded
                          ? l10n.sidebarCollapse
                          : l10n.sidebarExpand,
                      iconSize: 18,
                      size: 36,
                      borderRadius: tokens.radius.md,
                      foregroundColor: cs.hentai.textSecondary,
                      hoverColor: cs.hentai.sidebarItemHoverBackground,
                      overlayColor: cs.hentai.sidebarItemHoverBackground
                          .withAlpha(110),
                      delayTooltipThreeSeconds: false,
                      onPressed: onToggleExpanded,
                    ),
                  ),
                ),
                SizedBox(height: tokens.spacing.lg),
              ],
              Expanded(
                child: reorderMode
                    ? (librariesReorderPaneBuilder?.call(context) ??
                          const SizedBox.shrink())
                    : ListView(padding: EdgeInsets.zero, children: mainNav),
              ),
              if (!reorderMode)
                ...systemItems.map(
                  (NavItemData item) => _SidebarButton(
                    item: item,
                    isActive: activeId == item.id,
                    expandProgress: curvedT,
                    labelOpacity: labelOpacity,
                    showCollapsedTooltip: showCollapsedTooltip,
                    onTap: () => onDestinationSelected(item.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.item,
    required this.isActive,
    required this.expandProgress,
    required this.labelOpacity,
    required this.showCollapsedTooltip,
    required this.onTap,
  });

  final NavItemData item;
  final bool isActive;

  /// 0 = collapsed rail, 1 = expanded (already easeOutCubic-curved).
  final double expandProgress;
  final double labelOpacity;
  final bool showCollapsedTooltip;
  final VoidCallback onTap;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  static const Duration _kChromeAnimDuration = Duration(milliseconds: 220);
  static const Curve _kChromeAnimCurve = Curves.easeOutCubic;
  static const double _kCollapsedButtonSize = 36;

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final double t = widget.expandProgress.clamp(0.0, 1.0);

    final Color idleBackground = cs.hentai.sidebarBackground;
    final Color backgroundColor = widget.isActive
        ? cs.hentai.sidebarItemActiveBackground
        : (_isHovered ? cs.hentai.sidebarItemHoverBackground : idleBackground);

    final Color textColor = widget.isActive
        ? cs.hentai.textPrimary
        : (_isHovered ? cs.hentai.textPrimary : cs.hentai.textSecondary);

    final Color iconColor = widget.isActive
        ? cs.hentai.textPrimary
        : (_isHovered ? cs.hentai.textPrimary : cs.hentai.textSecondary);

    final Widget actionable = Semantics(
      button: true,
      label: widget.item.label,
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double maxWidth = constraints.maxWidth;
            final double buttonWidth =
                _kCollapsedButtonSize + (maxWidth - _kCollapsedButtonSize) * t;
            final double horizontalPadding = 12 * t;
            final Alignment align = Alignment.lerp(
              Alignment.center,
              Alignment.centerLeft,
              t,
            )!;

            return Align(
              alignment: align,
              child: SizedBox(
                width: buttonWidth,
                height: DesktopSidebar.navItemHeight,
                child: AnimatedContainer(
                  duration: _kChromeAnimDuration,
                  curve: _kChromeAnimCurve,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    // Keep border width constant so active chrome does not
                    // shift neighboring nav rows vertically.
                    border: Border.all(
                      width: 1,
                      color: widget.isActive
                          ? cs.hentai.sidebarItemActiveBorder
                          : idleBackground,
                    ),
                    boxShadow: widget.isActive
                        ? <BoxShadow>[
                            BoxShadow(
                              color: cs.hentai.sidebarItemActiveShadowColor,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Align(
                      alignment: t < 0.001
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AnimatedTheme(
                            duration: _kChromeAnimDuration,
                            curve: _kChromeAnimCurve,
                            data: theme.copyWith(
                              iconTheme: IconThemeData(
                                color: iconColor,
                                size: DesktopSidebar.navItemIconSize,
                              ),
                            ),
                            child: Icon(widget.item.icon),
                          ),
                          ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: t,
                              child: Opacity(
                                opacity: widget.labelOpacity,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: AnimatedDefaultTextStyle(
                                    duration: _kChromeAnimDuration,
                                    curve: _kChromeAnimCurve,
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      color: textColor,
                                      fontSize: 14,
                                      height: 1.2,
                                      fontWeight: widget.isActive
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    child: Text(
                                      widget.item.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.clip,
                                      strutStyle: const StrutStyle(
                                        fontSize: 14,
                                        height: 1.2,
                                        fontWeight: FontWeight.w600,
                                        forceStrutHeight: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: DesktopSidebar.navItemVerticalMargin,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: widget.showCollapsedTooltip
            ? Tooltip(
                message: widget.item.label,
                waitDuration: const Duration(seconds: 1),
                child: actionable,
              )
            : actionable,
      ),
    );
  }
}
