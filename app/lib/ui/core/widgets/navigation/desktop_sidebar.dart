import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/dto/nav_item_data.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/app_navigation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DesktopSidebar extends HookWidget {
  static const double expandedWidth = 256;
  static const double collapsedWidth = 72;
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

  const DesktopSidebar({
    super.key,
    required this.activeId,
    required this.isExpanded,
    this.showCollapseToggle = true,
    this.applyDrawerTopInset = false,
    required this.onToggleExpanded,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double topPadding = applyDrawerTopInset
        ? MediaQuery.viewPaddingOf(context).top + tokens.spacing.lg
        : 0;

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

    final l10n = context.l10n;
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

        return Container(
          width: width,
          height: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: cs.hentai.sidebarBackground,
            border: Border(right: BorderSide(color: cs.hentai.borderSubtle)),
          ),
          padding: EdgeInsets.fromLTRB(8, topPadding, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showCollapseToggle) ...<Widget>[
                Align(
                  alignment: toggleAlignment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: GhostButton.icon(
                      icon: LucideIcons.menu,
                      tooltip: '',
                      semanticLabel: isExpanded
                          ? l10n.sidebarCollapse
                          : l10n.sidebarExpand,
                      iconSize: 18,
                      size: 36,
                      borderRadius: 8,
                      foregroundColor: cs.hentai.textSecondary,
                      hoverColor: cs.hentai.sidebarItemHoverBackground,
                      overlayColor: cs.hentai.sidebarItemHoverBackground
                          .withAlpha(110),
                      delayTooltipThreeSeconds: false,
                      onPressed: onToggleExpanded,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ...menuItems.map(
                (NavItemData item) => _SidebarButton(
                  item: item,
                  isActive: activeId == item.id,
                  expandProgress: curvedT,
                  labelOpacity: labelOpacity,
                  showCollapsedTooltip: showCollapsedTooltip,
                  onTap: () => onDestinationSelected(item.id),
                ),
              ),
              const Spacer(),
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
                child: AnimatedContainer(
                  duration: _kChromeAnimDuration,
                  curve: _kChromeAnimCurve,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      width: widget.isActive ? 1 : 0.8,
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
                      vertical: 8,
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
                                size: 18,
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
                                      fontWeight: widget.isActive
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    child: Text(
                                      widget.item.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.clip,
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
      margin: const EdgeInsets.symmetric(vertical: 4),
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
