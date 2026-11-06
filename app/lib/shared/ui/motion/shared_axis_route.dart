import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/motion/spring_curve.dart';

/// Lab 统一页面转场（shared-axis 风格）。
///
/// 前进：页面从右侧水平滑入并淡入；后退：方向相反。
/// 空间位移使用 M3E expressive spatial 弹簧（允许轻微回弹），透明度使用 effects 弹簧。
/// 开启"减少动效"时直接切换，不播放任何位移。
PageRoute<T> sharedAxisRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final Duration duration = LabMotion.motionDurationOf(
    context,
    LabMotion.routeTransitionDuration,
  );
  final Curve spatialCurve = SpringCurve(
    motion: LabMotion.routeSpring,
    duration: LabMotion.routeTransitionDuration,
  );
  final Curve effectsCurve = SpringCurve(
    motion: LabMotion.effectsSpring,
    duration: LabMotion.routeTransitionDuration,
  );

  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return builder(routeContext);
        },
    transitionsBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          if (LabMotion.reduceMotionOf(routeContext)) {
            return child;
          }
          // 后退使用正向曲线的 flipped，保证反向时同样从边界开始运动，而不是在 1 附近停滞。
          final Animation<double> spatial = CurvedAnimation(
            parent: animation,
            curve: spatialCurve,
            reverseCurve: spatialCurve.flipped,
          );
          final Animation<double> effects = CurvedAnimation(
            parent: animation,
            curve: effectsCurve,
            reverseCurve: effectsCurve.flipped,
          );
          return FadeTransition(
            opacity: effects,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(spatial),
              child: child,
            ),
          );
        },
  );
}
