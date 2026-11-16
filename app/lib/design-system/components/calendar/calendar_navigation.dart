import 'package:flutter/material.dart';

/// Independent month/year controls used by the docked picker.
class CalendarNavigation extends StatelessWidget {
  const CalendarNavigation({
    required this.label,
    required this.menuKey,
    required this.focusNode,
    required this.active,
    required this.enabled,
    required this.previousLabel,
    required this.nextLabel,
    required this.menuHint,
    required this.onPrevious,
    required this.onNext,
    required this.onMenu,
    this.trailingArrows = false,
    this.showArrows = true,
    super.key,
  });
  final String label;
  final Key menuKey;
  final FocusNode focusNode;
  final bool active;
  final bool enabled;
  final String previousLabel;
  final String nextLabel;
  final String menuHint;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onMenu;
  final bool trailingArrows;
  final bool showArrows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final menu = Expanded(
      child: Tooltip(
        message: menuHint,
        child: TextButton(
          key: menuKey,
          focusNode: focusNode,
          onPressed: enabled ? onMenu : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: active ? colors.primary : colors.onSurfaceVariant,
            minimumSize: const Size(48, 48),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Visibility(
                visible: enabled,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Icon(
                  active ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        if (trailingArrows) menu,
        Visibility(
          visible: showArrows,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            tooltip: previousLabel,
            onPressed: enabled ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        if (!trailingArrows) menu,
        Visibility(
          visible: showArrows,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            tooltip: nextLabel,
            onPressed: enabled ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}
