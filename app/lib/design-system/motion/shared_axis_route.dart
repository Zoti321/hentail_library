import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'motion.dart';
import '../theme/color/desktop_shell_surfaces.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

/// Material Shared Axis 默认时长（与 `animations` 包 PageTransitions 一致）。
const Duration kSharedAxisRouteDuration = Duration(milliseconds: 300);

/// Lab / Navigator：[SharedAxisTransition] 页面路由。
///
/// 开启「减少动效」时直接切换，不播放位移。
PageRoute<T> sharedAxisRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  Color? fillColor,
}) {
  final Duration duration = LabMotion.motionDurationOf(
    context,
    kSharedAxisRouteDuration,
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
          return SharedAxisTransitionWrapper(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            fillColor: fillColor,
            child: child,
          );
        },
  );
}

/// Shared-axis 包装：减少动效时直出 child。
///
/// [reverse] 仅对水平轴有效：镜像滑动方向（系列上一卷从左侧进入）。
class SharedAxisTransitionWrapper extends StatelessWidget {
  const SharedAxisTransitionWrapper({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.transitionType = SharedAxisTransitionType.horizontal,
    this.fillColor,
    this.reverse = false,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;
  final SharedAxisTransitionType transitionType;
  final Color? fillColor;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    if (LabMotion.reduceMotionOf(context)) {
      return child;
    }
    final Color resolvedFill =
        fillColor ?? labBrowseCanvasColor(M3ETheme.of(context).colorScheme);
    final bool mirrorHorizontal =
        reverse && transitionType == SharedAxisTransitionType.horizontal;
    final Widget axisChild = mirrorHorizontal
        ? Transform.flip(flipX: true, child: child)
        : child;
    final Widget transition = SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: transitionType,
      fillColor: resolvedFill,
      child: axisChild,
    );
    if (!mirrorHorizontal) {
      return transition;
    }
    return Transform.flip(flipX: true, child: transition);
  }
}
