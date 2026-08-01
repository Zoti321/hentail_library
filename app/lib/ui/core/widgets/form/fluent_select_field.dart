import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 标签相对触发器的排列方式。
enum FluentSelectLabelLayout {
  /// 标签在上（表单字段默认）。
  stacked,

  /// 标签在左、触发器在右（设置行等）。
  inline,
}

/// 弹出菜单默认最大高度（仍受视口剩余空间约束）。
const double kFluentSelectMenuMaxHeight = 240;

/// 弹出菜单外观；未提供的字段使用 tokens / 组件默认值。
typedef FluentSelectMenuStyle = ({
  double? menuGap,
  double? menuBorderRadius,
  EdgeInsetsGeometry? menuPadding,
  EdgeInsetsGeometry? itemPadding,
  double? menuMaxHeight,
});

/// 构造可选菜单样式；未传字段保持 `null`，由字段解析为默认值。
FluentSelectMenuStyle fluentSelectMenuStyle({
  double? menuGap,
  double? menuBorderRadius,
  EdgeInsetsGeometry? menuPadding,
  EdgeInsetsGeometry? itemPadding,
  double? menuMaxHeight,
}) {
  return (
    menuGap: menuGap,
    menuBorderRadius: menuBorderRadius,
    menuPadding: menuPadding,
    itemPadding: itemPadding,
    menuMaxHeight: menuMaxHeight,
  );
}

/// Fluent 风格单选字段：标签 + 描边触发器 + 自绘弹出菜单。
///
/// 调用方依赖 [value] / [items] / [itemLabel] / [onChanged]；
/// 可选 [menuStyle]、[labelLayout]、[inlineTriggerWidth]。
class FluentSelectField<T> extends StatefulWidget {
  const FluentSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.labelText,
    this.labelTrailing,
    this.errorText,
    this.enabled = true,
    this.menuStyle,
    this.labelLayout = FluentSelectLabelLayout.stacked,
    this.inlineTriggerWidth = 180,
  });

  static const Key triggerKey = Key('fluent_select_field_trigger');
  static const Key menuPanelKey = Key('fluent_select_field_menu');

  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? labelText;
  final Widget? labelTrailing;
  final String? errorText;
  final bool enabled;
  final FluentSelectMenuStyle? menuStyle;
  final FluentSelectLabelLayout labelLayout;
  final double inlineTriggerWidth;

  @override
  State<FluentSelectField<T>> createState() => _FluentSelectFieldState<T>();
}

class _FluentSelectFieldState<T> extends State<FluentSelectField<T>> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _triggerBoxKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isFocused = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay(notify: false);
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _removeOverlay({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen) {
      _isOpen = false;
      if (notify && mounted) {
        setState(() {});
      }
    }
  }

  void _closeMenu() {
    if (!_isOpen) {
      return;
    }
    _removeOverlay();
  }

  void _toggleMenu() {
    if (!widget.enabled) {
      return;
    }
    if (_isOpen) {
      _closeMenu();
      return;
    }
    _openMenu();
  }

  void _openMenu() {
    if (_isOpen || !widget.enabled) {
      return;
    }
    final BuildContext? triggerContext = _triggerBoxKey.currentContext;
    if (triggerContext == null) {
      return;
    }
    final RenderBox triggerBox =
        triggerContext.findRenderObject()! as RenderBox;
    final RenderBox overlayBox =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset triggerTopLeft = triggerBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Rect anchorRect = triggerTopLeft & triggerBox.size;
    final AppThemeTokens tokens = context.tokens;
    final FluentSelectMenuStyle? style = widget.menuStyle;
    final double menuGap = style?.menuGap ?? tokens.spacing.xs;
    final double menuBorderRadius =
        style?.menuBorderRadius ?? tokens.radius.xs;
    final EdgeInsetsGeometry menuPadding =
        style?.menuPadding ?? EdgeInsets.all(tokens.spacing.xs);
    final EdgeInsetsGeometry itemPadding =
        style?.itemPadding ??
        EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.sm,
        );
    final double menuMaxHeight =
        style?.menuMaxHeight ?? kFluentSelectMenuMaxHeight;
    // OverlayEntry 挂在根 Overlay，不会自动继承字段处的 Theme（阅读页强制深色时尤其明显）。
    final ThemeData menuTheme = Theme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return Theme(
          data: menuTheme,
          child: _FluentSelectOverlay<T>(
            anchorRect: anchorRect,
            overlaySize: overlayBox.size,
            menuGap: menuGap,
            menuBorderRadius: menuBorderRadius,
            menuPadding: menuPadding,
            itemPadding: itemPadding,
            menuMaxHeight: menuMaxHeight,
            items: widget.items,
            value: widget.value,
            itemLabel: widget.itemLabel,
            onDismiss: _closeMenu,
            onSelected: (T item) {
              widget.onChanged(item);
              _closeMenu();
              _focusNode.unfocus();
            },
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_isOpen) {
        _closeMenu();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _toggleMenu();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildTrigger({
    required AppThemeTokens tokens,
    required ColorScheme cs,
    required Color borderColor,
    required Color textColor,
    required bool showActiveBorder,
    required bool hasError,
  }) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) => _handleKey(event),
      child: GestureDetector(
        onTap: widget.enabled
            ? () {
                _focusNode.requestFocus();
                _toggleMenu();
              }
            : null,
        child: KeyedSubtree(
          key: FluentSelectField.triggerKey,
          child: AnimatedContainer(
            key: _triggerBoxKey,
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: cs.hentai.inputBackground,
              borderRadius: BorderRadius.circular(tokens.radius.md),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: showActiveBorder
                  ? <BoxShadow>[
                      BoxShadow(
                        color: cs.primary.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.md,
                vertical: tokens.spacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.itemLabel(widget.value),
                      style: TextStyle(
                        fontSize: tokens.text.bodyMd,
                        color: textColor,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: widget.enabled
                        ? cs.onSurfaceVariant
                        : cs.hentai.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineLabel(AppThemeTokens tokens, ColorScheme cs) {
    final Color labelColor = widget.enabled
        ? cs.hentai.textSecondary
        : cs.hentai.textSecondary.withValues(alpha: 0.45);
    return Text(
      widget.labelText!,
      style: TextStyle(
        fontSize: tokens.text.bodySm,
        fontWeight: FontWeight.w500,
        color: labelColor,
        height: 1.3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;
    final bool showActiveBorder =
        widget.enabled && (_isFocused || _isOpen) && !hasError;
    final Color borderColor = hasError
        ? cs.error
        : showActiveBorder
        ? cs.hentai.inputBorderActive
        : cs.hentai.inputBorder;
    final Color textColor = widget.enabled
        ? cs.hentai.textPrimary
        : cs.hentai.textSecondary;

    final Widget trigger = _buildTrigger(
      tokens: tokens,
      cs: cs,
      borderColor: borderColor,
      textColor: textColor,
      showActiveBorder: showActiveBorder,
      hasError: hasError,
    );

    if (widget.labelLayout == FluentSelectLabelLayout.inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (widget.labelText != null)
                Expanded(child: _buildInlineLabel(tokens, cs)),
              SizedBox(
                width: widget.inlineTriggerWidth,
                child: trigger,
              ),
            ],
          ),
          if (hasError) ...[
            SizedBox(height: tokens.spacing.xs),
            Text(
              widget.errorText!,
              style: TextStyle(
                fontSize: tokens.text.labelXs,
                color: cs.error,
                height: 1.3,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.labelText != null) ...[
          FormLabel(widget.labelText!, trailing: widget.labelTrailing),
          SizedBox(height: tokens.spacing.sm - 2),
        ],
        trigger,
        if (hasError) ...[
          SizedBox(height: tokens.spacing.xs),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.error,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

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
              color: isSelected ? cs.primary : cs.hentai.textPrimary,
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
