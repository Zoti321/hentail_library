import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

typedef ContentSwitcherBottomBarItem = ({IconData icon, String label});

/// Compact content switcher: icon above label, suitable for Scaffold.bottomNavigationBar.
class ContentSwitcherBottomBar extends StatelessWidget {
  const ContentSwitcherBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ContentSwitcherBottomBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _barHeight = 56;
  static const double _iconSize = 20;
  static const double _labelFontSize = 11;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.hentai.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _barHeight,
            child: Row(
              children: List<Widget>.generate(items.length, (int index) {
                final ContentSwitcherBottomBarItem item = items[index];
                final bool selected = index == selectedIndex;
                final Color foreground = selected
                    ? cs.primary
                    : cs.onSurfaceVariant;
                return Expanded(
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(item.icon, size: _iconSize, color: foreground),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _labelFontSize,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
