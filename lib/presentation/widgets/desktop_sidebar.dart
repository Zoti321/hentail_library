import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
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

    final List<NavItemData> menuItems = [
      const NavItemData(id: 'home', label: '首页', icon: LucideIcons.house),
      const NavItemData(id: 'library', label: '漫画库', icon: LucideIcons.library),
      const NavItemData(id: 'folders', label: '文件夹', icon: LucideIcons.folder),
      const NavItemData(id: 'tags', label: '标签', icon: LucideIcons.tags),
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
      width: 256,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.sidebarBackground,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      padding: .fromLTRB(8, 0, 8, 16),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          DragToMoveArea(child: SizedBox(height: 32, width: double.infinity)),
          // 1. app title /logo
          DragToMoveArea(
            child: Padding(
              padding: .symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'H',
                      style: TextStyle(
                        color: Colors.white,
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
          _buildSectionHeader(context, '菜单'),
          ...menuItems.map(
            (item) => _SidebarButton(
              item: item,
              isActive: activeId == item.id,
              onTap: () => onDestinationSelected(item.id),
            ),
          ),
          const Spacer(),
          // 3. System Section
          _buildSectionHeader(context, '系统'),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.textSecondary,
          letterSpacing: 0.8,
        ),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 选中状态样式（悬停色无主题等价，保留原值以保证零视觉变更）
    final Color backgroundColor = widget.isActive
        ? theme.colorScheme.surface
        : (_isHovered ? Colors.grey.withOpacity(0.1) : Colors.transparent);

    final Color textColor = widget.isActive
        ? theme.colorScheme.textPrimary
        : (_isHovered
              ? theme.colorScheme.textPrimary
              : theme.colorScheme.textSecondary);

    final Color iconColor = widget.isActive
        ? theme.colorScheme.primary
        : (_isHovered
              ? theme.colorScheme.textPrimary
              : theme.colorScheme.textSecondary);

    return Container(
      margin: .symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: BoxBorder.all(
                width: 0.8,
                color: widget.isActive
                    ? theme.colorScheme.borderSubtle
                    : Colors.transparent,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: .symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(widget.item.icon, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Text(
                        widget.item.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isActive)
                  Positioned(
                    left: 4,
                    top: 12,
                    bottom: 12,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
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
