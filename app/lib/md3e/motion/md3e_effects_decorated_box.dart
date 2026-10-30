import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:motor/motor.dart';

/// 背景 / 形状变化：[BoxDecoration] 的过渡由 M3E 效果弹簧驱动（无位移，仅颜色与圆角）。
///
/// 目标变化时从当前显示的装饰接续，不会跳变。圆角非零时裁剪子组件，与 AnimatedContainer 行为一致。
/// 开启"减少动效"时直接切换到目标装饰。
class Md3eEffectsDecoratedBox extends StatefulWidget {
  const Md3eEffectsDecoratedBox({
    super.key,
    required this.decoration,
    required this.child,
  });

  final BoxDecoration decoration;
  final Widget child;

  @override
  State<Md3eEffectsDecoratedBox> createState() =>
      _Md3eEffectsDecoratedBoxState();
}

class _Md3eEffectsDecoratedBoxState extends State<Md3eEffectsDecoratedBox>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;
  late BoxDecoration _from = widget.decoration;
  late BoxDecoration _to = widget.decoration;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: Md3eMotion.effectsSpring,
      vsync: this,
      initialValue: 1,
    );
  }

  @override
  void didUpdateWidget(Md3eEffectsDecoratedBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decoration == widget.decoration) {
      return;
    }
    // 从当前显示的装饰接续，避免中途切换时跳变。
    _from = _currentDecoration();
    _to = widget.decoration;
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

  BoxDecoration _currentDecoration() {
    final double t = _controller.value.clamp(0.0, 1.0);
    return BoxDecoration.lerp(_from, _to, t) ?? _to;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final BoxDecoration decoration = _currentDecoration();
        final BorderRadius? radius = decoration.borderRadius?.resolve(
          Directionality.maybeOf(context) ?? TextDirection.ltr,
        );
        Widget content = child!;
        if (radius != null && radius != BorderRadius.zero) {
          content = ClipRRect(borderRadius: radius, child: content);
        }
        return DecoratedBox(decoration: decoration, child: content);
      },
    );
  }
}
