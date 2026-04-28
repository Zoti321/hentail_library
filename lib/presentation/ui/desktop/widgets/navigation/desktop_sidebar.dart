import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/dto/nav_item_data.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/shared/navigation/app_navigation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DesktopSidebar extends StatelessWidget {
  static const double expandedWidth = 256;
  static const double collapsedWidth = 72;

  final String activeId;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onDestinationSelected;

  const DesktopSidebar({
    super.key,
    required this.activeId,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final List<NavItemData> menuItems = AppNavigation.desktopMainNavItems;
    final List<NavItemData> systemItems = AppNavigation.desktopSystemNavItems;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isExpanded ? expandedWidth : collapsedWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: cs.sidebarBackground,
        border: Border(right: BorderSide(color: cs.borderSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
              child: GhostButton.icon(
                icon: isExpanded
                    ? LucideIcons.panelLeftClose
                    : LucideIcons.panelLeftOpen,
                tooltip: '',
                semanticLabel: isExpanded ? '收起侧边栏' : '展开侧边栏',
                iconSize: 18,
                size: 32,
                borderRadius: 8,
                foregroundColor: cs.textSecondary,
                hoverColor: cs.sidebarItemHoverBackground,
                overlayColor: cs.sidebarItemHoverBackground.withAlpha(110),
                delayTooltipThreeSeconds: false,
                onPressed: onToggleExpanded,
              ),
            ),
          ),
          SizedBox(height: 16),
          // 2. menu section
          ...menuItems.map(
            (item) => _SidebarButton(
              item: item,
              isActive: activeId == item.id,
              isExpanded: isExpanded,
              onTap: () => onDestinationSelected(item.id),
            ),
          ),
          const Spacer(),
          // 3. System Section
          ...systemItems.map(
            (item) => _SidebarButton(
              item: item,
              isActive: activeId == item.id,
              isExpanded: isExpanded,
              onTap: () => onDestinationSelected(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatefulWidget {
  final NavItemData item;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.item,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  static const Duration _kItemAnimDuration = Duration(milliseconds: 220);
  static const Curve _kItemAnimCurve = Curves.easeOutCubic;
  static const double _kCollapsedButtonSize = 36;

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final Color idleBackground = cs.sidebarBackground;
    final Color backgroundColor = widget.isActive
        ? cs.sidebarItemActiveBackground
        : (_isHovered ? cs.sidebarItemHoverBackground : idleBackground);

    final Color textColor = widget.isActive
        ? cs.textPrimary
        : (_isHovered ? cs.textPrimary : cs.textSecondary);

    final Color iconColor = widget.isActive
        ? cs.textPrimary
        : (_isHovered ? cs.textPrimary : cs.textSecondary);

    final Widget buttonBody = widget.isExpanded
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                AnimatedTheme(
                  duration: _kItemAnimDuration,
                  curve: _kItemAnimCurve,
                  data: theme.copyWith(
                    iconTheme: IconThemeData(color: iconColor, size: 18),
                  ),
                  child: Icon(widget.item.icon),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: _kItemAnimDuration,
                    curve: _kItemAnimCurve,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    child: Text(
                      widget.item.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.square(
            dimension: _kCollapsedButtonSize,
            child: Center(
              child: AnimatedTheme(
                duration: _kItemAnimDuration,
                curve: _kItemAnimCurve,
                data: theme.copyWith(
                  iconTheme: IconThemeData(color: iconColor, size: 18),
                ),
                child: Icon(widget.item.icon),
              ),
            ),
          );
    final Widget actionable = Semantics(
      button: true,
      label: widget.item.label,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _kItemAnimDuration,
          curve: _kItemAnimCurve,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              width: widget.isActive ? 1 : 0.8,
              color: widget.isActive
                  ? cs.sidebarItemActiveBorder
                  : idleBackground,
            ),
            boxShadow: widget.isActive
                ? <BoxShadow>[
                    BoxShadow(
                      color: cs.sidebarItemActiveShadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: buttonBody,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: widget.isExpanded
            ? actionable
            : Tooltip(
                message: widget.item.label,
                waitDuration: const Duration(seconds: 1),
                child: actionable,
              ),
      ),
    );
  }
}
