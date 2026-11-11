import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/motion/motion.dart';
import 'package:motor/motor.dart';

/// 尺寸展开 / 收起：高度因子由 M3E 空间弹簧驱动，展开时允许越过终点回弹。
///
/// 适合小面积控件（chip 槽等）。大块列表 / 分组内容请用 [SpringExpandPanel]
///（对齐 M3E expandable：高度 clamp、淡入、轻微上滑，避免滚动区橡皮筋）。
///
/// 收起到弹簧底部（≤0）时不再渲染子树，尺寸为零。开启"减少动效"时直接切换。
class SpringSize extends StatefulWidget {
  const SpringSize({
    super.key,
    required this.expanded,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final bool expanded;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  State<SpringSize> createState() => _SpringSizeState();
}

class _SpringSizeState extends State<SpringSize>
    with SingleTickerProviderStateMixin {
  /// 弹簧收敛时的残余值视为收起（约 0.1% 高度，肉眼不可辨）。
  static const double _hiddenFactor = 0.001;

  /// 无界控制器：弹簧允许过冲，超出 [0, 1] 的部分直接体现为尺寸回弹。
  late final SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: LabMotion.spatialReveal,
      vsync: this,
      initialValue: widget.expanded ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(SpringSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) {
      return;
    }
    final double target = widget.expanded ? 1 : 0;
    if (LabMotion.reduceMotionOf(context)) {
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
    if (LabMotion.reduceMotionOf(context)) {
      return widget.expanded ? widget.child : const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double factor = _controller.value;
        if (factor <= _hiddenFactor) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Align(
            alignment: widget.alignment,
            heightFactor: factor,
            child: child,
          ),
        );
      },
    );
  }
}
