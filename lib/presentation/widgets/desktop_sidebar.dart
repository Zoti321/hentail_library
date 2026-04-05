import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

// 导航项数据模型
class NavItemData {
  final String id;
  final String label;
  final IconData icon;

  const NavItemData({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class DesktopSidebar extends StatelessWidget {
  /// Matches [Container] width; keep in sync with title bar content offset.
  static const double kWidth = 256;

  final String activeId;
  final ValueChanged<String> onDestinationSelected;

  const DesktopSidebar({
    super.key,
    required this.activeId,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final List<NavItemData> menuItems = [
      const NavItemData(id: 'home', label: '首页', icon: LucideIcons.house),
      const NavItemData(id: 'library', label: '漫画库', icon: LucideIcons.library),
      const NavItemData(
        id: 'selectedPaths',
        label: '选中路径',
        icon: LucideIcons.folderTree,
      ),
      const NavItemData(id: 'tags', label: '标签', icon: LucideIcons.tags),
      const NavItemData(id: 'series', label: '系列', icon: LucideIcons.layers),
      const NavItemData(id: 'history', label: '历史', icon: LucideIcons.history),
    ];
    final List<NavItemData> systemItems = [
      const NavItemData(
        id: 'settings',
        label: '设置',
        icon: LucideIcons.settings,
      ),
    ];

    return Container(
      width: kWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: cs.sidebarBackground,
        border: Border(right: BorderSide(color: cs.borderSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DragToMoveArea(child: SizedBox(height: 32, width: double.infinity)),
          // 1. app title /logo
          DragToMoveArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'H',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hentai Library',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 2. menu section
          ...menuItems.map(
            (item) => _SidebarButton(
              item: item,
              isActive: activeId == item.id,
              onTap: () => onDestinationSelected(item.id),
            ),
          ),
          const Spacer(),
          // 3. System Section
          ...systemItems.map(
            (item) => _SidebarButton(
              item: item,
              isActive: activeId == item.id,
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
  final VoidCallback onTap;

  const _SidebarButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  static const Duration _kItemAnimDuration = Duration(milliseconds: 220);
  static const Curve _kItemAnimCurve = Curves.easeOutCubic;

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 勿用 Colors.transparent：与实色做 Color.lerp 会先经过发灰的半透明中间态。
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      AnimatedTheme(
                        duration: _kItemAnimDuration,
                        curve: _kItemAnimCurve,
                        data: theme.copyWith(
                          iconTheme: IconThemeData(color: iconColor, size: 18),
                        ),
                        child: Icon(widget.item.icon),
                      ),
                      const SizedBox(width: 8),
                      AnimatedDefaultTextStyle(
                        duration: _kItemAnimDuration,
                        curve: _kItemAnimCurve,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        child: Text(widget.item.label),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 12,
                  bottom: 12,
                  child: AnimatedOpacity(
                    duration: _kItemAnimDuration,
                    curve: _kItemAnimCurve,
                    opacity: widget.isActive ? 1 : 0,
                    child: AnimatedSlide(
                      duration: _kItemAnimDuration,
                      curve: _kItemAnimCurve,
                      offset: widget.isActive
                          ? Offset.zero
                          : const Offset(-0.35, 0),
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: cs.sidebarItemActiveIndicator,
                          borderRadius: BorderRadius.circular(2),
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
    );
  }
}
