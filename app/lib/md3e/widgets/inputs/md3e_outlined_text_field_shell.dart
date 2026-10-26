import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/text_fields/components/m3e_text_field_container_painter.dart';
import 'package:material_3_expressive/components/text_fields/components/m3e_text_field_label.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Builds the editable region inside [Md3eOutlinedTextFieldShell].
typedef Md3eOutlinedTextFieldInputBuilder = Widget Function(
  BuildContext context,
  M3ETextFieldColors colors,
  M3ETextFieldTheme fieldTheme,
  TextStyle inputStyle,
);

/// Outlined `M3ETextField` shell with a custom input slot.
///
/// Container paint, notch, floating label, hover, and keyboard focus ring follow
/// `material_3_expressive` `M3ETextField` (outlined). The package does not yet
/// expose a composable slot; this mirrors its private build path.
class Md3eOutlinedTextFieldShell extends StatefulWidget {
  const Md3eOutlinedTextFieldShell({
    super.key,
    required this.label,
    required this.focusNode,
    required this.inputBuilder,
    this.enabled = true,
    this.isPopulated = false,
    this.leading,
    this.trailing,
    this.onTapOutside,
    this.fieldTheme,
  });

  final String label;
  final FocusNode focusNode;
  final Md3eOutlinedTextFieldInputBuilder inputBuilder;
  final bool enabled;
  final bool isPopulated;
  final Widget? leading;
  final Widget? trailing;
  final TapRegionCallback? onTapOutside;
  final M3ETextFieldTheme? fieldTheme;

  @override
  State<Md3eOutlinedTextFieldShell> createState() =>
      _Md3eOutlinedTextFieldShellState();
}

class _Md3eOutlinedTextFieldShellState extends State<Md3eOutlinedTextFieldShell>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _focused = false;
  bool _showFocusRing = false;
  late final AnimationController _labelMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChange);
    M3EFocusInteraction.instance.addListener(_handleFocusInteractionChanged);
    _syncLabel(progress: _labelProgress, animate: false);
  }

  @override
  void didUpdateWidget(Md3eOutlinedTextFieldShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLabel(progress: _labelProgress, animate: true);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    FocusManager.instance.removeHighlightModeListener(
      _handleHighlightModeChange,
    );
    M3EFocusInteraction.instance.removeListener(_handleFocusInteractionChanged);
    _labelMotion.dispose();
    super.dispose();
  }

  bool get _floating =>
      widget.enabled && (_focused || widget.isPopulated);

  double get _labelProgress => _floating ? 1 : 0;

  M3ETextFieldTheme _fieldThemeOf(M3EThemeData theme) =>
      widget.fieldTheme ?? theme.textFieldTheme;

  M3ETextFieldStates get _states => M3ETextFieldStates(
        enabled: widget.enabled,
        hovered: _hovered,
        focused: _focused,
        error: false,
      );

  void _syncLabel({required double progress, required bool animate}) {
    if (!animate ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _labelMotion.value = progress;
      return;
    }
    _labelMotion.animateTo(progress);
  }

  void _handleFocusChange() {
    setState(() {
      _focused = widget.focusNode.hasFocus;
      _showFocusRing = M3EFocusRing.shouldShow(widget.focusNode, context);
      _syncLabel(progress: _labelProgress, animate: true);
    });
  }

  void _handleHighlightModeChange(FocusHighlightMode mode) {
    if (!mounted) {
      return;
    }
    final bool show = M3EFocusRing.shouldShow(widget.focusNode, context);
    if (show != _showFocusRing) {
      setState(() => _showFocusRing = show);
    }
  }

  void _handleFocusInteractionChanged() {
    if (!mounted) {
      return;
    }
    final bool show = M3EFocusRing.shouldShow(widget.focusNode, context);
    if (_showFocusRing != show) {
      setState(() => _showFocusRing = show);
    }
  }

  void _updateHover({required bool hovered}) {
    if (_hovered == hovered) {
      return;
    }
    setState(() => _hovered = hovered);
  }

  _Md3eTextFieldNotch _notch(
    M3EThemeData theme,
    M3ETextFieldTheme fieldTheme,
    double labelStart,
    double progress,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: M3ETextFieldLabel.compose(widget.label, isRequired: false),
        style: fieldTheme.resolveFloatingLabelStyle(theme.typeScale),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double full = painter.width + fieldTheme.notchPadding * 2;
    painter.dispose();
    final double width = full * progress.clamp(0, 1);
    return _Md3eTextFieldNotch(
      labelStart - fieldTheme.notchPadding + (full - width) / 2,
      width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETextFieldTheme fieldTheme = _fieldThemeOf(theme);
    final M3ETextFieldColors colors = fieldTheme.resolveColors(
      theme.colorScheme,
      variant: M3ETextFieldVariant.outlined,
      states: _states,
    );
    final int density = fieldTheme.density;
    final double height = fieldTheme.heightFor(density);
    final double start = widget.leading == null
        ? fieldTheme.horizontalPadding
        : fieldTheme.iconSlotWidth + fieldTheme.iconSlotTextPadding;
    final double end = widget.trailing == null
        ? fieldTheme.horizontalPadding
        : fieldTheme.iconSlotWidth + fieldTheme.iconSlotTextPadding;

    final TextStyle inputStyle = fieldTheme
        .resolveInputStyle(theme.typeScale)
        .copyWith(color: colors.inputText);

    final Widget container = AnimatedBuilder(
      animation: _labelMotion,
      builder: (BuildContext context, Widget? _) {
        final double progress = _labelMotion.value;
        final _Md3eTextFieldNotch notch = _notch(
          theme,
          fieldTheme,
          start,
          progress,
        );
        return CustomPaint(
          painter: M3ETextFieldContainerPainter(
            outlined: true,
            shape: fieldTheme.outlinedShape,
            containerColor: colors.container,
            stateLayerColor: colors.stateLayer,
            strokeColor: colors.stroke,
            strokeWidth: colors.strokeWidth,
            textDirection: Directionality.of(context),
            notchStart: notch.start,
            notchWidth: notch.width,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ..._leadingSlot(fieldTheme, colors, height),
                    Expanded(
                      child: _buildInputSlot(
                        theme,
                        fieldTheme,
                        colors,
                        height,
                        inputStyle,
                      ),
                    ),
                    ..._trailingSlot(fieldTheme, colors, height),
                  ],
                ),
              ),
              _buildLabel(
                theme,
                fieldTheme,
                colors,
                height,
                start,
                end,
                progress,
              ),
            ],
          ),
        );
      },
    );

    final double floatingLine = M3ETextFieldTheme.lineHeightOf(
      fieldTheme.resolveFloatingLabelStyle(theme.typeScale),
    );

    return TextFieldTapRegion(
      enabled: widget.enabled,
      onTapOutside:
          widget.onTapOutside ?? M3EFocus.tapOutsideHandler(widget.focusNode),
      child: Padding(
        padding: EdgeInsets.only(top: floatingLine / 2),
        child: ExcludeFocus(
          excluding: !widget.enabled,
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            onEnter: (_) => _updateHover(hovered: true),
            onExit: (_) => _updateHover(hovered: false),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => M3EFocusInteraction.instance
                  .notePointerInteraction(immediate: true),
              child: M3EFocusRing(
                focused: _showFocusRing,
                radius: fieldTheme.outlinedShape,
                color: colors.focusRing,
                width: fieldTheme.focusRingWidth,
                gap: fieldTheme.focusRingGap,
                child: container,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSlot(
    M3EThemeData theme,
    M3ETextFieldTheme fieldTheme,
    M3ETextFieldColors colors,
    double height,
    TextStyle inputStyle,
  ) {
    final double inputLine = M3ETextFieldTheme.lineHeightOf(inputStyle);
    final double centered = (height - inputLine) / 2;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: centered),
      child: widget.inputBuilder(context, colors, fieldTheme, inputStyle),
    );
  }

  Widget _buildLabel(
    M3EThemeData theme,
    M3ETextFieldTheme fieldTheme,
    M3ETextFieldColors colors,
    double height,
    double start,
    double end,
    double progress,
  ) {
    final TextStyle resting = fieldTheme.resolveLabelStyle(theme.typeScale);
    final TextStyle floating = fieldTheme.resolveFloatingLabelStyle(
      theme.typeScale,
    );
    final double restingTop =
        (height - M3ETextFieldTheme.lineHeightOf(resting)) / 2;
    final double floatingTop =
        -M3ETextFieldTheme.lineHeightOf(floating) / 2;
    return PositionedDirectional(
      start: start,
      end: end,
      top: lerpDouble(restingTop, floatingTop, progress),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        heightFactor: 1,
        child: IgnorePointer(
          child: M3ETextFieldLabel(
            text: widget.label,
            progress: progress,
            restingStyle: resting,
            floatingStyle: floating,
            color: colors.label,
          ),
        ),
      ),
    );
  }

  List<Widget> _leadingSlot(
    M3ETextFieldTheme fieldTheme,
    M3ETextFieldColors colors,
    double height,
  ) {
    if (widget.leading == null) {
      return <Widget>[SizedBox(width: fieldTheme.horizontalPadding)];
    }
    return <Widget>[
      SizedBox(
        width: fieldTheme.iconSlotWidth,
        height: height,
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(
              color: colors.leadingIcon,
              size: fieldTheme.iconSize,
            ),
            child: widget.leading!,
          ),
        ),
      ),
      SizedBox(width: fieldTheme.iconSlotTextPadding),
    ];
  }

  List<Widget> _trailingSlot(
    M3ETextFieldTheme fieldTheme,
    M3ETextFieldColors colors,
    double height,
  ) {
    if (widget.trailing == null) {
      return <Widget>[SizedBox(width: fieldTheme.horizontalPadding)];
    }
    return <Widget>[
      SizedBox(width: fieldTheme.iconSlotTextPadding),
      SizedBox(
        width: fieldTheme.iconSlotWidth,
        height: height,
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(
              color: colors.trailingIcon,
              size: fieldTheme.iconSize,
            ),
            child: widget.trailing!,
          ),
        ),
      ),
    ];
  }
}

@immutable
class _Md3eTextFieldNotch {
  const _Md3eTextFieldNotch(this.start, this.width);

  final double start;
  final double width;
}
