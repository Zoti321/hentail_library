import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/design-system/motion/motion.dart';
import 'package:hentai_library/design-system/theme/color/desktop_shell_surfaces.dart';
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
          return sharedAxisTransitionWrapper(
            context: routeContext,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            fillColor: fillColor,
            child: child,
          );
        },
  );
}

/// go_router：[SharedAxisTransition] 页面（详情 → 阅读等层级下钻）。
///
/// 对齐 Lab [sharedAxisRoute]；勿用于 Shell 顶层切换（顶层用 fade-through）。
CustomTransitionPage<void> buildSharedAxisPage({
  required GoRouterState state,
  required Widget child,
  SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  Color? fillColor,
  Duration? transitionDuration,
  bool reverse = false,
}) {
  final Duration duration = transitionDuration ?? kSharedAxisRouteDuration;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return sharedAxisTransitionWrapper(
            context: context,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            fillColor: fillColor,
            reverse: reverse,
            child: child,
          );
        },
    child: child,
  );
}

/// Shared-axis 包装：减少动效时直出 child。
///
/// [reverse] 仅对水平轴有效：镜像滑动方向（系列上一卷从左侧进入）。
Widget sharedAxisTransitionWrapper({
  required BuildContext context,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
  SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
  Color? fillColor,
  bool reverse = false,
}) {
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
