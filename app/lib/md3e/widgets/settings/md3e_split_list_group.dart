import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_effects_decorated_box.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_exclude.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double kMd3eSplitListInnerRadius = 4;
const double kMd3eSplitListRowGap = 4;

/// 拖拽浮层的外观（颜色、圆角）。由可拖拽分段组注入，行据此绘制浮层背景。
class Md3eSplitDragScope extends InheritedWidget {
  const Md3eSplitDragScope({
    required this.color,
    required this.radius,
    required super.child,
    super.key,
  });

  final Color color;
  final double radius;

  static Md3eSplitDragScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Md3eSplitDragScope>();
  }

  @override
  bool updateShouldNotify(Md3eSplitDragScope oldWidget) {
    return color != oldWidget.color || radius != oldWidget.radius;
  }
}

/// One row inside [Md3eSplitListGroup]; animates corner radius on press.
class Md3eSplitListRow extends StatefulWidget {
  const Md3eSplitListRow({
    super.key,
    required this.child,
    this.topRadius = kMd3eSplitListInnerRadius,
    this.bottomRadius = kMd3eSplitListInnerRadius,
    this.pressedRadius = kMd3eTonalSurfaceRadius,
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
        .dependOnInheritedWidgetOfExactType<_Md3eSplitRowScope>()
        ?.onPressChanged;
  }

  @override
  State<Md3eSplitListRow> createState() => _Md3eSplitListRowState();
}

class _Md3eSplitListRowState extends State<Md3eSplitListRow> {
  bool _pressed = false;

  /// 本次按下是否落在 [Md3eReorderExclude] 区域（如行内「更多」按钮）内；
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
    final Md3eSplitDragScope? drag = Md3eSplitDragScope.maybeOf(context);
    final Widget child = widget.onTap == null
        ? widget.child
        : Listener(
            onPointerDown: (PointerDownEvent event) => _pressStartedInExclude =
                md3eIsPointerInReorderExclude(context, event.position),
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

    return Md3eEffectsDecoratedBox(
      decoration: BoxDecoration(
        color: drag?.color ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(topRadius),
          bottom: Radius.circular(bottomRadius),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _Md3eSplitRowScope(onPressChanged: _reportPress, child: child),
      ),
    );
  }
}

class _Md3eSplitRowScope extends InheritedWidget {
  const _Md3eSplitRowScope({
    required this.onPressChanged,
    required super.child,
  });

  final ValueChanged<bool> onPressChanged;

  @override
  bool updateShouldNotify(_Md3eSplitRowScope oldWidget) => false;
}

/// Stacked settings rows with outer 24dp radius and 4dp gutters.
class Md3eSplitListGroup extends StatelessWidget {
  const Md3eSplitListGroup({
    super.key,
    required this.children,
    this.outerRadius = kMd3eTonalSurfaceRadius,
  });

  final List<Widget> children;
  final double outerRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: kMd3eSplitListRowGap),
          Md3eSplitListRow(
            topRadius: i == 0 ? outerRadius : kMd3eSplitListInnerRadius,
            bottomRadius: i == children.length - 1
                ? outerRadius
                : kMd3eSplitListInnerRadius,
            pressedRadius: outerRadius,
            child: children[i],
          ),
        ],
      ],
    );
  }
}
