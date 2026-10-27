import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Suggestion [M3EChip] 容器绘制（与 `m3e_chips.dart` 启用态一致），[child] 替换标签槽。
///
/// [editingFocusNode] 交给内层 [EditableText]；[staticChrome] 为 true 时不绘制焦点环/状态层。
class Md3eSuggestionChipSurface extends StatefulWidget {
  const Md3eSuggestionChipSurface({
    super.key,
    required this.editingFocusNode,
    required this.onPressed,
    required this.child,
    this.width,
    this.staticChrome = false,
  });

  final FocusNode editingFocusNode;
  final VoidCallback onPressed;
  final Widget child;
  final double? width;

  /// 草稿输入：外观与未聚焦 suggestion chip 一致，仅靠内层光标表示可编辑。
  final bool staticChrome;

  @override
  State<Md3eSuggestionChipSurface> createState() =>
      _Md3eSuggestionChipSurfaceState();
}

class _Md3eSuggestionChipSurfaceState extends State<Md3eSuggestionChipSurface> {
  static const M3EChipType _chipType = M3EChipType.suggestion;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EChipTheme chipTheme = theme.chipTheme;
    final M3EColorScheme scheme = theme.colorScheme;

    final Color stateLayer = chipTheme.stateLayerColor(
      scheme,
      selected: false,
      type: _chipType,
    );
    final Color labelColor = chipTheme.labelColor(
      scheme,
      enabled: true,
      selected: false,
      type: _chipType,
    );

    final M3EInteractionState interaction = widget.staticChrome
        ? const M3EInteractionState(
            hovered: false,
            focused: false,
            pressed: false,
            dragged: false,
          )
        : M3EInteractionState(
            hovered: _hovered,
            focused: widget.editingFocusNode.hasFocus,
            pressed: false,
            dragged: false,
          );

    final Widget chip = TapRegion(
      onTapOutside: (_) {
        M3EFocusInteraction.instance.notePointerInteraction();
        if (widget.editingFocusNode.hasFocus) {
          widget.editingFocusNode.unfocus();
        }
      },
      child: M3EComponentTheme(
        builder: (BuildContext context) {
          final Widget surface = _buildSurface(
            theme: theme,
            chipTheme: chipTheme,
            scheme: scheme,
            state: interaction,
            stateLayer: stateLayer,
            labelColor: labelColor,
            child: widget.child,
          );
          if (widget.staticChrome) {
            return surface;
          }
          return MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: surface,
          );
        },
      ),
    );

    if (widget.width == null) {
      return chip;
    }
    return SizedBox(width: widget.width, child: chip);
  }

  Widget _buildSurface({
    required M3EThemeData theme,
    required M3EChipTheme chipTheme,
    required M3EColorScheme scheme,
    required M3EInteractionState state,
    required Color stateLayer,
    required Color labelColor,
    required Widget child,
  }) {
    final BorderRadius radius = chipTheme.borderRadius;
    final double outlineWidth = chipTheme.resolvedOutlineWidth(
      type: _chipType,
      selected: false,
      elevated: false,
    );
    const bool hasLeading = false;
    const bool hasTrailing = false;
    final double opacity = chipTheme.stateLayerOpacity(state);
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: outlineWidth == 0
          ? BorderSide.none
          : BorderSide(
              color: chipTheme.outlineColor(
                scheme,
                enabled: true,
                focused: widget.staticChrome ? false : state.focused,
                type: _chipType,
              ),
              width: outlineWidth,
            ),
    );
    final List<BoxShadow> shadows = M3EElevation.shadows(
      chipTheme.elevation(elevated: false, dragged: false),
      shadowColor: scheme.shadow,
    );

    final Widget content = Container(
      height: chipTheme.height,
      width: widget.width,
      foregroundDecoration: opacity == 0
          ? null
          : BoxDecoration(
              color: stateLayer.withValues(alpha: opacity),
              borderRadius: radius,
            ),
      child: Padding(
        padding: EdgeInsets.only(
          left: chipTheme.startPadding(
            type: _chipType,
            hasLeading: hasLeading,
            hasAvatar: false,
          ),
          right: chipTheme.endPaddingFor(hasTrailing: hasTrailing),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
            style: theme.typeScale.labelLarge.copyWith(color: labelColor),
            maxLines: 1,
            overflow: TextOverflow.clip,
            child: child,
          ),
        ),
      ),
    );

    final Widget surface = Material(
      color: chipTheme.containerColor(
        scheme,
        enabled: true,
        selected: false,
        elevated: false,
        type: _chipType,
      ),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: _chipInkWell(
        onTap: widget.onPressed,
        shape: shape,
        splash: stateLayer,
        splashOpacity: chipTheme.pressedStateLayerOpacity,
        child: content,
      ),
    );

    final Widget framed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: surface,
    );

    if (widget.staticChrome) {
      return framed;
    }

    return M3EFocusRing(
      focused: state.focused,
      radius: radius,
      color: chipTheme.resolveFocusIndicatorColor(scheme),
      width: chipTheme.focusIndicatorThickness,
      gap: chipTheme.focusIndicatorOffset,
      child: framed,
    );
  }

  Widget _chipInkWell({
    required VoidCallback onTap,
    required ShapeBorder shape,
    required Color splash,
    required double splashOpacity,
    required Widget child,
  }) {
    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        excludeFromSemantics: true,
        customBorder: shape,
        splashFactory: InkSparkle.splashFactory,
        splashColor: splash.withValues(alpha: splashOpacity),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        child: child,
      ),
    );
  }
}
