import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

class DialogSideTabItem {
  const DialogSideTabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Dialog 左侧竖向 tab：选中项左侧主题色指示条 + 图标 + 文案。
class DialogSideTabBar extends StatelessWidget {
  const DialogSideTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.width = 148,
    this.showDivider = true,
  });

  final List<DialogSideTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double width;
  final bool showDivider;

  static const double itemHeight = 40;
  static const double indicatorWidth = 2;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                  right: BorderSide(color: cs.hentai.borderSubtle, width: 1),
                ),
              )
            : const BoxDecoration(),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(items.length, (int index) {
                final DialogSideTabItem item = items[index];
                return _DialogSideTabButton(
                  item: item,
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                  itemHeight: itemHeight,
                  horizontalPadding: tokens.spacing.md,
                );
              }),
            ),
            if (selectedIndex >= 0 && selectedIndex < items.length)
              Positioned(
                left: 0,
                top: selectedIndex * itemHeight,
                height: itemHeight,
                width: indicatorWidth,
                child: ColoredBox(color: cs.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogSideTabButton extends StatelessWidget {
  const _DialogSideTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.itemHeight,
    required this.horizontalPadding,
  });

  final DialogSideTabItem item;
  final bool selected;
  final VoidCallback onTap;
  final double itemHeight;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: cs.primary.withAlpha(16),
        child: SizedBox(
          height: itemHeight,
          child: Padding(
            padding: EdgeInsets.only(left: horizontalPadding),
            child: Row(
              children: <Widget>[
                Icon(
                  item.icon,
                  size: 16,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
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
