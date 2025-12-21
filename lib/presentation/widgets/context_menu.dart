import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FluentContextMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required String mangaTitle,
    required Function(String) onAction,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final screenSize = MediaQuery.of(context).size;
    double left = position.dx;
    double top = position.dy;
    const double width = 220;
    const double height = 300;

    if (left + width > screenSize.width) left = screenSize.width - width - 10;
    if (top + height > screenSize.height) top = screenSize.height - height - 10;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => entry.remove(),
              onSecondaryTap: () => entry.remove(),
            ),
          ),

          // 菜单
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: _MenuContent(
                title: mangaTitle,
                onClose: () => entry.remove(),
                onAction: onAction,
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }
}

class _MenuContent extends HookConsumerWidget {
  const _MenuContent({
    required this.title,
    required this.onClose,
    required this.onAction,
  });

  final String title;
  final VoidCallback onClose;
  final Function(String) onAction;

  void _handle(String action) {
    onAction(action);
    onClose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          // header
          Padding(
            padding: const .symmetric(horizontal: 12, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.textPlaceholder,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Primary Actions
          _FluentMenuItem(
            icon: LucideIcons.bookOpen, // BookOpen
            label: "阅读",
            shortcut: "Enter",
            onTap: () => _handle('read'),
          ),
          _FluentMenuItem(
            icon: LucideIcons.info,
            label: "查看详情",
            onTap: () => _handle('detail'),
          ),

          Divider(
            height: 8,
            thickness: 1,
            color: theme.colorScheme.surfaceContainerHighest,
          ),

          // Management Actions
          _FluentMenuItem(
            icon: LucideIcons.squarePen,
            label: "编辑元数据",
            onTap: () => _handle('edit'),
          ),
          _FluentMenuItem(
            icon: LucideIcons.layers,
            label: "合并",
            onTap: () => _handle('merge'),
          ),
          _FluentMenuItem(
            icon: LucideIcons.externalLink,
            label: "打开文件夹",
            onTap: () => _handle('open_folder'),
          ),

          Divider(
            height: 9,
            thickness: 1,
            color: theme.colorScheme.surfaceContainerHighest,
          ),

          // Destructive Actions
          _FluentMenuItem(
            icon: LucideIcons.trash2,
            label: "删除",
            shortcut: "Del",
            isDestructive: true,
            onTap: () => _handle('delete'),
          ),
        ],
      ),
    );
  }
}

class _FluentMenuItem extends HookWidget {
  const _FluentMenuItem({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState<bool>(false);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isHovered.value
                ? (isDestructive
                      ? Theme.of(context).colorScheme.error.withAlpha(10)
                      : Theme.of(context).colorScheme.buttonPressed)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDestructive
                    ? Theme.of(context).colorScheme.error
                    : (isHovered.value
                          ? Theme.of(context).colorScheme.textPrimary
                          : Theme.of(context).colorScheme.textSecondary),
              ),
              const SizedBox(width: 12),
              // label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.textPrimary,
                  ),
                ),
              ),
              if (shortcut != null)
                Text(
                  shortcut!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.textDisabled,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
