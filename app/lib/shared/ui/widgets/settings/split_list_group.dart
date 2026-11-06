import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/effects_decorated_box.dart';
import 'package:hentai_library/shared/ui/widgets/lists/reorder_exclude.dart';
import 'package:hentai_library/shared/ui/widgets/settings/tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double kSplitListInnerRadius = 4;
const double kSplitListRowGap = 4;

/// 拖拽浮层的外观（颜色、圆角）。由可拖拽分段组注入，行据此绘制浮层背景。
class SplitDragScope extends InheritedWidget {
  const SplitDragScope({
    required this.color,
    required this.radius,
    required super.child,
    super.key,
  });

  final Color color;
  final double radius;

  static SplitDragScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SplitDragScope>();
  }

  @override
  bool updateShouldNotify(SplitDragScope oldWidget) {
    return color != oldWidget.color || radius != oldWidget.radius;
  }
}

/// One row inside [SplitListGroup]; animates corner radius on press.
class SplitListRow extends StatefulWidget {
  const SplitListRow({
    super.key,
    required this.child,
    this.topRadius = kSplitListInnerRadius,
    this.bottomRadius = kSplitListInnerRadius,
    this.pressedRadius = kTonalSurfaceRadius,
    this.onTap,
    this.mouseCursor,
  });

  final Widget child;
  final double topRadius;
  final double bottomRadius;
  final double pressedRadius;
  final VoidCallback? onTap;
  final MouseCursor? mouseCursor;

  static ValueChanged<bool>? pressReporterOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SplitRowScope>()
        ?.onPressChanged;
  }

  @override
  State<SplitListRow> createState() => _SplitListRowState();
}

class _SplitListRowState extends State<SplitListRow> {
  bool _pressed = false;

  /// 本次按下是否落在 [ReorderExclude] 区域（如行内「更多」按钮）内；
  /// 是则不触发行点击，避免点控件时误打开整行。
  bool _pressStartedInExclude = false;

  void _reportPress(bool pressed) => setState(() => _pressed = pressed);

  void _handleTap() {
    if (_pressStartedInExclude) {
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme colors = M3ETheme.of(context).colorScheme;
    final SplitDragScope? drag = SplitDragScope.maybeOf(context);
    final Widget child = widget.onTap == null
        ? widget.child
        : Listener(
            onPointerDown: (PointerDownEvent event) => _pressStartedInExclude =
                isPointerInReorderExclude(context, event.position),
            child: InkWell(
              onTap: _handleTap,
              mouseCursor: widget.mouseCursor,
              onHighlightChanged: _reportPress,
              child: widget.child,
            ),
          );

    final double topRadius =
        drag?.radius ?? (_pressed ? widget.pressedRadius : widget.topRadius);
    final double bottomRadius =
        drag?.radius ?? (_pressed ? widget.pressedRadius : widget.bottomRadius);

    return EffectsDecoratedBox(
      decoration: BoxDecoration(
        color: drag?.color ?? colors.surfaceContainer,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(topRadius),
          bottom: Radius.circular(bottomRadius),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _SplitRowScope(onPressChanged: _reportPress, child: child),
      ),
    );
  }
}

class _SplitRowScope extends InheritedWidget {
  const _SplitRowScope({required this.onPressChanged, required super.child});

  final ValueChanged<bool> onPressChanged;

  @override
  bool updateShouldNotify(_SplitRowScope oldWidget) => false;
}

/// Stacked settings rows with outer 24dp radius and 4dp gutters.
class SplitListGroup extends StatelessWidget {
  const SplitListGroup({
    super.key,
    required this.children,
    this.outerRadius = kTonalSurfaceRadius,
  });

  final List<Widget> children;
  final double outerRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: kSplitListRowGap),
          SplitListRow(
            topRadius: i == 0 ? outerRadius : kSplitListInnerRadius,
            bottomRadius: i == children.length - 1
                ? outerRadius
                : kSplitListInnerRadius,
            pressedRadius: outerRadius,
            child: children[i],
          ),
        ],
      ],
    );
  }
}
