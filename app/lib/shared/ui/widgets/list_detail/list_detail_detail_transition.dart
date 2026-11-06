import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/motion/spring_curve.dart';

/// Kazumi 风 list-detail **详情区**切换：水平 slide + fade，M3E spatial 弹簧（可轻微过冲）。
///
/// 左侧导航不变，仅 [switchKey] 变化时对本 pane 做转场（设置分类、库/元数据表单侧栏 Tab 等）。
/// 透明度按 MD3 Clean fades 先出后入，避免快速切换时新旧文字交叉叠影。
class ListDetailDetailTransition extends StatelessWidget {
  const ListDetailDetailTransition({
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
    if (LabMotion.reduceMotionOf(context)) {
      return child;
    }

    final Duration duration = LabMotion.motionDurationOf(
      context,
      LabMotion.routeTransitionDuration,
    );
    final Curve springCurve = SpringCurve(
      motion: LabMotion.routeSpring,
      duration: LabMotion.routeTransitionDuration,
    );
    final ValueKey<Object> activeKey = ValueKey<Object>(switchKey);

    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        switchInCurve: springCurve,
        switchOutCurve: springCurve.flipped,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          // 只保留最近一层 outgoing，减轻连点时多层半透明叠字。
          return Stack(
            alignment: Alignment.topLeft,
            fit: StackFit.passthrough,
            children: <Widget>[
              if (previousChildren.isNotEmpty) previousChildren.last,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isIncoming = child.key == activeKey;
          final Offset begin = isIncoming
              ? incomingSlideBegin
              : outgoingSlideBegin;
          final Animation<double> opacity = isIncoming
              ? animation.drive(_ListDetailFadeThroughEnterTween())
              : animation.drive(_ListDetailFadeThroughOutgoingTween());
          return SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: opacity, child: child),
          );
        },
        child: KeyedSubtree(key: activeKey, child: child),
      ),
    );
  }
}

/// Incoming：前半程透明，后半程淡入。
///
/// [t] 可能因弹簧过冲略超出 \[0, 1\]，内部会 clamp。
@visibleForTesting
double listDetailFadeThroughEnterOpacity(double t) {
  if (t <= 0.5) {
    return 0.0;
  }
  if (t >= 1.0) {
    return 1.0;
  }
  return Curves.easeOutCubic.transform((t - 0.5) / 0.5);
}

/// Outgoing 收到的是 [AnimatedSwitcher] 的 ReverseAnimation（1→0）。
/// 在前半程（reverse 值 1→0.5）淡出，后半程保持 0，避免与 incoming 叠字。
///
/// [reverseAnimationValue] 可能因弹簧过冲略超出 \[0, 1\]，内部会 clamp。
@visibleForTesting
double listDetailFadeThroughOutgoingOpacity(double reverseAnimationValue) {
  if (reverseAnimationValue <= 0.5) {
    return 0.0;
  }
  if (reverseAnimationValue >= 1.0) {
    return 1.0;
  }
  return Curves.easeInCubic.transform(
    (reverseAnimationValue - 0.5) / 0.5,
  );
}

final class _ListDetailFadeThroughEnterTween extends Animatable<double> {
  @override
  double transform(double t) => listDetailFadeThroughEnterOpacity(t);
}

final class _ListDetailFadeThroughOutgoingTween extends Animatable<double> {
  @override
  double transform(double t) => listDetailFadeThroughOutgoingOpacity(t);
}
