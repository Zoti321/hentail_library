import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';

/// 单项：胶囊 Tab 内的一段文字，可选图标。
class CapsuleTabItem {
  const CapsuleTabItem({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// 水平胶囊分段控件，用于在同一页面内切换子模块（如作者 / 标签 / 系列）。
class CapsuleTabBar extends StatelessWidget {
  const CapsuleTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<CapsuleTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _height = 40;
  static const double _radius = 999;
  static const EdgeInsets _padding = EdgeInsets.all(4);

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(items.length, (int i) {
            final bool selected = i == selectedIndex;
            final CapsuleTabItem item = items[i];
            return Padding(
              padding: EdgeInsets.only(right: i < items.length - 1 ? 4 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_radius),
                  onTap: () => onSelected(i),
                  hoverColor: cs.primary.withAlpha(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: _height - 8,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary.withAlpha(38) : Colors.transparent,
                      borderRadius: BorderRadius.circular(_radius),
                      border: selected
                          ? Border.all(color: cs.primary.withAlpha(120))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (item.icon != null) ...<Widget>[
                          Icon(
                            item.icon,
                            size: 16,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
