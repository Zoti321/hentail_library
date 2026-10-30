import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:motor/motor.dart';

/// 位移 + 透明度显隐：由 M3E 空间弹簧驱动。
///
/// 显示时从 [hiddenOffset] 位置弹入并允许回弹越过终点；隐藏时沿同一弹簧收回。
/// 完全隐藏后不接收指针与语义。开启"减少动效"时直接切换。
class Md3eSpringReveal extends StatefulWidget {
  const Md3eSpringReveal({
    super.key,
    required this.visible,
    required this.hiddenOffset,
    required this.child,
  });

  final bool visible;

  /// 隐藏状态下子组件相对原位置的偏移（显示时归零）。
  final Offset hiddenOffset;
  final Widget child;

  @override
  State<Md3eSpringReveal> createState() => _Md3eSpringRevealState();
}

class _Md3eSpringRevealState extends State<Md3eSpringReveal>
    with SingleTickerProviderStateMixin {
  /// 无界控制器：过冲时透明度 clamp 到 [0, 1]，位移保留过冲。
  late final SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: Md3eMotion.spatialReveal,
      vsync: this,
      initialValue: widget.visible ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(Md3eSpringReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) {
      return;
    }
    final double target = widget.visible ? 1 : 0;
    if (Md3eMotion.reduceMotionOf(context)) {
      _controller.value = target;
    } else {
      _controller.animateTo(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Md3eMotion.reduceMotionOf(context)) {
      return IgnorePointer(
        ignoring: !widget.visible,
        child: ExcludeSemantics(
          excluding: !widget.visible,
          child: Opacity(opacity: widget.visible ? 1 : 0, child: widget.child),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double raw = _controller.value;
        final double opacity = raw.clamp(0.0, 1.0);
        final Offset offset = widget.hiddenOffset * (1 - raw);
        return IgnorePointer(
          ignoring: opacity <= 0.01,
          child: ExcludeSemantics(
            excluding: opacity <= 0.01,
            child: Transform.translate(
              offset: offset,
              child: Opacity(opacity: opacity, child: child),
            ),
          ),
        );
      },
    );
  }
}
