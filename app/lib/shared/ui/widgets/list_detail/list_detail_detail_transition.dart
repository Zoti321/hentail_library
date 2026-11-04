import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/motion/spring_curve.dart';

/// Kazumi 风 list-detail **详情区**切换：水平 slide + fade，M3E spatial 弹簧（可轻微过冲）。
///
/// 左侧导航不变，仅 [switchKey] 变化时对本 pane 做转场（设置分类、库/元数据表单侧栏 Tab 等）。
class Md3eListDetailDetailTransition extends StatelessWidget {
  const Md3eListDetailDetailTransition({
    super.key,
    required this.switchKey,
    required this.child,
    this.incomingSlideBegin = const Offset(0.12, 0),
    this.outgoingSlideBegin = const Offset(-0.08, 0),
  });

  final Object switchKey;
  final Widget child;

  /// 新内容自右侧滑入（fractional translation）。
  final Offset incomingSlideBegin;

  /// 旧内容向左侧滑出。
  final Offset outgoingSlideBegin;

  @override
  Widget build(BuildContext context) {
    if (Md3eMotion.reduceMotionOf(context)) {
      return child;
    }

    final Duration duration = Md3eMotion.motionDurationOf(
      context,
      Md3eMotion.routeTransitionDuration,
    );
    final Curve springCurve = Md3eSpringCurve(
      motion: Md3eMotion.routeSpring,
      duration: Md3eMotion.routeTransitionDuration,
    );
    final ValueKey<Object> activeKey = ValueKey<Object>(switchKey);

    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        switchInCurve: springCurve,
        switchOutCurve: springCurve.flipped,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[...previousChildren, ?currentChild],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isIncoming = child.key == activeKey;
          final Offset begin = isIncoming
              ? incomingSlideBegin
              : outgoingSlideBegin;
          return SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: KeyedSubtree(key: activeKey, child: child),
      ),
    );
  }
}
