part of 'fluent_select_field.dart';

// 弹出菜单内部私有控件（#309 part 拆分）：遮罩、布局委托与菜单项。
class _FluentSelectOverlay<T> extends StatelessWidget {
  const _FluentSelectOverlay({
    required this.anchorRect,
    required this.overlaySize,
    required this.menuGap,
    required this.menuBorderRadius,
    required this.menuPadding,
    required this.itemPadding,
    required this.menuMaxHeight,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onDismiss,
    required this.onSelected,
  });

  final Rect anchorRect;
  final Size overlaySize;
  final double menuGap;
  final double menuBorderRadius;
  final EdgeInsetsGeometry menuPadding;
  final EdgeInsetsGeometry itemPadding;
  final double menuMaxHeight;
  final List<T> items;
  final T value;
  final String Function(T item) itemLabel;
  final VoidCallback onDismiss;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => onDismiss(),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _FluentSelectMenuLayoutDelegate(
            anchorRect: anchorRect,
            overlaySize: overlaySize,
            menuGap: menuGap,
            menuMaxHeight: menuMaxHeight,
          ),
          child: PopupMenuPanelShell(
            key: FluentSelectField.menuPanelKey,
            width: anchorRect.width,
            blurRadius: 6,
            shadowOffset: const Offset(0, 4),
            borderRadius: menuBorderRadius,
            child: Padding(
              padding: menuPadding,
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final T item = items[index];
                  final bool isSelected = item == value;
                  return _FluentSelectMenuItem(
                    label: itemLabel(item),
                    isSelected: isSelected,
                    itemPadding: itemPadding,
                    fontSize: tokens.text.bodyMd,
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FluentSelectMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _FluentSelectMenuLayoutDelegate({
    required this.anchorRect,
    required this.overlaySize,
    required this.menuGap,
    required this.menuMaxHeight,
  });

  final Rect anchorRect;
  final Size overlaySize;
  final double menuGap;
  final double menuMaxHeight;

  double get _spaceBelow =>
      math.max(0, overlaySize.height - anchorRect.bottom - menuGap);

  double get _spaceAbove => math.max(0, anchorRect.top - menuGap);

  double get _sideBudget => math.max(_spaceBelow, _spaceAbove);

  double get _resolvedMaxHeight => math.min(menuMaxHeight, _sideBudget);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: anchorRect.width,
      maxWidth: anchorRect.width,
      maxHeight: _resolvedMaxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bool showBelow =
        childSize.height <= _spaceBelow || _spaceBelow >= _spaceAbove;
    final double dy = showBelow
        ? anchorRect.bottom + menuGap
        : anchorRect.top - menuGap - childSize.height;
    return Offset(anchorRect.left, dy);
  }

  @override
  bool shouldRelayout(covariant _FluentSelectMenuLayoutDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        overlaySize != oldDelegate.overlaySize ||
        menuGap != oldDelegate.menuGap ||
        menuMaxHeight != oldDelegate.menuMaxHeight;
  }
}

class _FluentSelectMenuItem extends StatelessWidget {
  const _FluentSelectMenuItem({
    required this.label,
    required this.isSelected,
    required this.itemPadding,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final EdgeInsetsGeometry itemPadding;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color selectedFill = cs.primary.withAlpha(14);
    final Color hoverFill = cs.primary.withAlpha(10);

    return Material(
      color: isSelected ? selectedFill : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isSelected ? Colors.transparent : hoverFill,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return selectedFill;
          }
          if (states.contains(WidgetState.hovered) && !isSelected) {
            return hoverFill;
          }
          return Colors.transparent;
        }),
        child: Padding(
          padding: itemPadding,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? cs.primary : context.hentai.textPrimary,
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
