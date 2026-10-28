import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field_selection_scope.dart';
import 'package:material_3_expressive/components/text_fields/components/m3e_text_field_container_painter.dart';
import 'package:material_3_expressive/components/text_fields/components/m3e_text_field_label.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:motor/motor.dart';

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
/// `material_3_expressive` `M3ETextField` (outlined). Used for composable
/// inputs ([Md3eTagInputField]); ordinary fields use [Md3eOutlinedTextField].
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
    this.selectionController,
    this.editableTextKey,
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
  final TextEditingController? selectionController;
  final GlobalKey<EditableTextState>? editableTextKey;

  @override
  State<Md3eOutlinedTextFieldShell> createState() =>
      _Md3eOutlinedTextFieldShellState();
}

class _Md3eOutlinedTextFieldShellState extends State<Md3eOutlinedTextFieldShell>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _focused = false;
  bool _showFocusRing = false;
  late final SingleMotionController _labelMotion = SingleMotionController(
    motion: _springOf(M3EMotion.spatialFast),
    vsync: this,
  );
  late final SingleMotionController _effectsMotion = SingleMotionController(
    motion: _springOf(M3EMotion.effectsFast),
    vsync: this,
    initialValue: 1,
  );
  late final Listenable _motion = Listenable.merge(<Listenable>[
    _labelMotion,
    _effectsMotion,
  ]);
  double? _floatTarget;
  M3ETextFieldColors? _fromColors;
  M3ETextFieldColors? _toColors;

  static SpringMotion _springOf(M3ESpring spring) =>
      SpringMotion(spring.toDescription(), snapToEnd: true);

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChange);
    M3EFocusInteraction.instance.addListener(_handleFocusInteractionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncVisuals(animate: _toColors != null);
  }

  @override
  void didUpdateWidget(Md3eOutlinedTextFieldShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPopulated != widget.isPopulated ||
        oldWidget.enabled != widget.enabled) {
      _syncVisuals();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    FocusManager.instance.removeHighlightModeListener(
      _handleHighlightModeChange,
    );
    M3EFocusInteraction.instance.removeListener(_handleFocusInteractionChanged);
    _labelMotion.dispose();
    _effectsMotion.dispose();
    super.dispose();
  }

  bool get _floating =>
      ((_focused && widget.enabled) || widget.isPopulated);

  M3ETextFieldColors get _currentColors {
    final M3ETextFieldColors to = _toColors!;
    return M3ETextFieldColors.lerp(
      _fromColors ?? to,
      to,
      _effectsMotion.value.clamp(0, 1),
    );
  }

  M3ETextFieldTheme _fieldThemeOf(M3EThemeData theme) =>
      widget.fieldTheme ?? theme.textFieldTheme;

  M3ETextFieldStates get _states => M3ETextFieldStates(
        enabled: widget.enabled,
        hovered: _hovered,
        focused: _focused,
        error: false,
      );

  void _syncVisuals({bool animate = true}) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETextFieldTheme fieldTheme = _fieldThemeOf(theme);
    final bool instant =
        !animate || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    _labelMotion.motion = _springOf(fieldTheme.labelSpring);
    _effectsMotion.motion = _springOf(fieldTheme.effectsSpring);

    final double float = _floating ? 1 : 0;
    if (_floatTarget != float) {
      _floatTarget = float;
      if (instant) {
        _labelMotion.value = float;
      } else {
        _labelMotion.animateTo(float);
      }
    }

    final M3ETextFieldColors colors = fieldTheme.resolveColors(
      theme.colorScheme,
      variant: M3ETextFieldVariant.outlined,
      states: _states,
    );
    if (colors == _toColors) {
      return;
    }
    _fromColors = _toColors == null ? colors : _currentColors;
    _toColors = colors;
    if (instant) {
      _effectsMotion.value = 1;
    } else {
      _effectsMotion.animateTo(1, from: 0);
    }
  }

  void _handleFocusChange() {
    setState(() {
      _focused = widget.focusNode.hasFocus;
      _showFocusRing = M3EFocusRing.shouldShow(widget.focusNode, context);
      _syncVisuals();
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
    setState(() {
      _hovered = hovered;
      _syncVisuals();
    });
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
    final int density = fieldTheme.density;
    final double height = fieldTheme.heightFor(density);
    final double start = widget.leading == null
        ? fieldTheme.horizontalPadding
        : fieldTheme.iconSlotWidth + fieldTheme.iconSlotTextPadding;
    final double end = (widget.trailing == null
        ? fieldTheme.horizontalPadding
        : fieldTheme.iconSlotWidth + fieldTheme.iconSlotTextPadding);

    final Widget container = ListenableBuilder(
      listenable: _motion,
      builder: (BuildContext context, Widget? _) {
        final M3ETextFieldColors colors = _currentColors;
        final double progress = _labelMotion.value;
        final _Md3eTextFieldNotch notch = _notch(
          theme,
          fieldTheme,
          start,
          progress,
        );
        final TextStyle inputStyle = fieldTheme
            .resolveInputStyle(theme.typeScale)
            .copyWith(color: colors.inputText);

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

    final Widget focusRingChild = M3EFocusRing(
      focused: _showFocusRing,
      radius: fieldTheme.outlinedShape,
      color: _toColors?.focusRing,
      width: fieldTheme.focusRingWidth,
      gap: fieldTheme.focusRingGap,
      child: container,
    );

    final Widget interactive = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => M3EFocusInteraction.instance
          .notePointerInteraction(immediate: true),
      child: focusRingChild,
    );

    final bool useSelectionGestures = widget.selectionController != null &&
        widget.editableTextKey != null;

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
            child: useSelectionGestures
                ? Md3eOutlinedTextFieldSelectionScope(
                    focusNode: widget.focusNode,
                    controller: widget.selectionController!,
                    enabled: widget.enabled,
                    editableTextKey: widget.editableTextKey!,
                    child: interactive,
                  )
                : interactive,
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
