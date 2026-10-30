import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:motor/motor.dart';

/// 数值补间：目标值变化时，从当前显示值向新目标值的过渡由 M3E 效果弹簧驱动（非线性）。
///
/// 中途变化目标时从当前显示值接续，不跳变。开启"减少动效"时直接到达目标值。
class Md3eSpringValue extends StatefulWidget {
  const Md3eSpringValue({
    super.key,
    required this.value,
    required this.builder,
    this.motion = Md3eMotion.effectsSpring,
    this.child,
  });

  final double value;

  /// 默认效果弹簧（无过冲）；需要回弹时传入空间弹簧（如 [Md3eMotion.spatialReveal]）。
  final Motion motion;

  /// 不随数值变化的子组件，原样传给 [builder]。
  final Widget? child;

  final Widget Function(BuildContext context, double value, Widget? child)
  builder;

  @override
  State<Md3eSpringValue> createState() => _Md3eSpringValueState();
}

class _Md3eSpringValueState extends State<Md3eSpringValue>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;
  late double _from = widget.value;
  late double _to = widget.value;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: widget.motion,
      vsync: this,
      initialValue: 1,
    );
  }

  @override
  void didUpdateWidget(Md3eSpringValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) {
      return;
    }
    _from = _current();
    _to = widget.value;
    if (Md3eMotion.reduceMotionOf(context)) {
      _controller.value = 1;
    } else {
      _controller.value = 0;
      _controller.animateTo(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _current() => _from + (_to - _from) * _controller.value;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return widget.builder(context, _current(), child);
      },
    );
  }
}
