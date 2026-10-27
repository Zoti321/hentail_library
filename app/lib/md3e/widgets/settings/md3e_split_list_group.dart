import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double kMd3eSplitListInnerRadius = 4;
const double kMd3eSplitListRowGap = 4;

/// One row inside [Md3eSplitListGroup]; animates corner radius on press.
class Md3eSplitListRow extends StatefulWidget {
  const Md3eSplitListRow({
    super.key,
    required this.child,
    this.topRadius = kMd3eSplitListInnerRadius,
    this.bottomRadius = kMd3eSplitListInnerRadius,
    this.pressedRadius = kMd3eTonalSurfaceRadius,
    this.onTap,
  });

  final Widget child;
  final double topRadius;
  final double bottomRadius;
  final double pressedRadius;
  final VoidCallback? onTap;

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

  void _reportPress(bool pressed) => setState(() => _pressed = pressed);

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme colors = M3ETheme.of(context).colorScheme;
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    final Duration duration = Md3eMotion.motionDurationOf(
      context,
      const Duration(milliseconds: 250),
    );
    final Widget child = widget.onTap == null
        ? widget.child
        : InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _reportPress,
            child: widget.child,
          );

    return AnimatedContainer(
      duration: duration,
      curve: Md3eMotion.curveForStateEnter(reduceMotion: reduceMotion),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            _pressed ? widget.pressedRadius : widget.topRadius,
          ),
          bottom: Radius.circular(
            _pressed ? widget.pressedRadius : widget.bottomRadius,
          ),
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
