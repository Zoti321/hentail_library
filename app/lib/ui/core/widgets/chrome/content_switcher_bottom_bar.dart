import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/interaction/interactive_target.dart';
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double labelFontSize = tokens.text.labelXs;

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
                final Color background = selected
                    ? cs.primary.withAlpha(28)
                    : Colors.transparent;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: Material(
                      color: background,
                      child: InkWell(
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                        hoverColor: cs.surfaceContainer,
                        onTap: () {
                          onSelected(index);
                          unfocusAfterPointerActivation();
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(item.icon, size: _iconSize, color: foreground),
                            SizedBox(height: tokens.spacing.xs),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: labelFontSize,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: foreground,
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
        ),
      ),
    );
  }
}
