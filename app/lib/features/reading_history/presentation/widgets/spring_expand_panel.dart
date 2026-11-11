import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:motor/motor.dart';

/// 列表 / 分组内容展开：对齐 M3E [M3EExpandableSublist] 的运动语义。
///
/// - 进度由 [LabMotion.spatialReveal]（expressive spatial default）驱动
/// - **高度因子 clamp 到 [0, 1]**，避免大块内容在滚动列表里橡皮筋回弹
/// - 透明度随高度因子（effects 语义：无过冲）
/// - 展开时内容自下方 [slideExtent] 滑入（进度可略过冲以带动位移回弹）
///
/// 与 [SpringSize] 不同：后者允许 `heightFactor > 1` 的尺寸过冲，适合小控件；
/// 本组件用于时间分组网格等大面积内容；分组网格应对外报告完整高度并在内部虚拟化行。
class SpringExpandPanel extends StatefulWidget {
  const SpringExpandPanel({
    super.key,
    required this.expanded,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.slideExtent = 12,
    this.expandMotion = LabMotion.spatialReveal,
    this.collapseMotion = LabMotion.spatialReveal,
  });

  final bool expanded;
  final Widget child;
  final AlignmentGeometry alignment;

  /// 折叠态内容相对终点的下偏移（展开过程中收到 0）。对齐 M3E expandable 的 12。
  final double slideExtent;

  final Motion expandMotion;
  final Motion collapseMotion;

  @override
  State<SpringExpandPanel> createState() => _SpringExpandPanelState();
}

class _SpringExpandPanelState extends State<SpringExpandPanel>
    with SingleTickerProviderStateMixin {
  static const double _hiddenFactor = 0.001;

  late final SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: widget.expanded ? widget.expandMotion : widget.collapseMotion,
      vsync: this,
      initialValue: widget.expanded ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(SpringExpandPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) {
      return;
    }
    final double target = widget.expanded ? 1 : 0;
    if (LabMotion.reduceMotionOf(context)) {
      _controller.value = target;
      return;
    }
    _controller.motion = widget.expanded
        ? widget.expandMotion
        : widget.collapseMotion;
    _controller.animateTo(target);
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
        final double progress = _controller.value;
        // 与 M3EExpandableSublist 一致：高度不回弹；位移可用略过冲的 t。
        final double t = progress.clamp(0.0, 1.2);
        final double heightFactor = progress <= 0 ? 0.0 : t.clamp(0.0, 1.0);
        if (heightFactor <= _hiddenFactor) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Align(
            alignment: widget.alignment,
            heightFactor: heightFactor,
            child: Opacity(
              opacity: heightFactor,
              child: Transform.translate(
                offset: Offset(0, (1.0 - t) * widget.slideExtent),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
