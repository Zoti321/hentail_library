import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:motor/motor.dart';

/// 在 [Stack] 中定位的矩形（位置 + 尺寸）由 M3E 空间弹簧驱动，允许越过终点回弹。
///
/// 目标矩形变化时从当前显示的矩形接续。开启"减少动效"时直接到达目标。
class Md3eSpringPositioned extends StatefulWidget {
  const Md3eSpringPositioned({
    super.key,
    required this.rect,
    required this.child,
  });

  final Rect rect;
  final Widget child;

  @override
  State<Md3eSpringPositioned> createState() => _Md3eSpringPositionedState();
}

class _Md3eSpringPositionedState extends State<Md3eSpringPositioned>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;
  late Rect _from = widget.rect;
  late Rect _to = widget.rect;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: Md3eMotion.spatialReveal,
      vsync: this,
      initialValue: 1,
    );
  }

  @override
  void didUpdateWidget(Md3eSpringPositioned oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rect == widget.rect) {
      return;
    }
    _from = _currentRect();
    _to = widget.rect;
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

  Rect _currentRect() => Rect.lerp(_from, _to, _controller.value) ?? _to;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final Rect rect = _currentRect();
        return Positioned.fromRect(rect: rect, child: child!);
      },
    );
  }
}
