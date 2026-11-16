import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:animations/animations.dart';

/// 库浏览 → 漫画/系列详情等带封面 Hero 的路由页。
///
/// 不用 desktop fade-through（前半段目标页 opacity=0 会让 Hero 落地闪一下）。
/// 对齐 Kazumi：普通 Material 系淡入，共享封面由 [Hero] 在 overlay 上飞行。
///
/// 系列内切卷请 [pushReplacement] 并传 [CatalogSeriesNavExtra]，改用水平 Shared Axis；
/// 勿用 [GoRouter.go]，以免清空库浏览 → 系列详情底层栈。

/// 漫画/系列详情「同级切卷」路由 extra（[GoRouterState.extra]）。
@immutable
class CatalogSeriesNavExtra {
  const CatalogSeriesNavExtra({required this.reverse});

  /// `true`：切到更靠前的卷（从左侧进入）。
  final bool reverse;
}

CustomTransitionPage<void> buildCatalogDetailPage({
  required GoRouterState state,
  required Widget child,
}) {
  final Object? extra = state.extra;
  if (extra is CatalogSeriesNavExtra) {
    // reduce-motion 由 sharedAxisTransitionWrapper 处理；此处用标准时长。
    return buildSharedAxisPage(
      state: state,
      child: child,
      reverse: extra.reverse,
      transitionDuration: kSharedAxisRouteDuration,
    );
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    transitionDuration: kCatalogDetailPageTransitionDuration,
    reverseTransitionDuration: kCatalogDetailPageTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        CatalogDetailTransition(animation: animation, child: child),
    child: child,
  );
}

/// Shared [go_router] page with desktop fade-through.
CustomTransitionPage<void> buildDesktopFadeThroughPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    transitionDuration: kDesktopPageTransitionDuration,
    reverseTransitionDuration: kDesktopPageTransitionDuration,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return DesktopFadeThroughTransitionWrapper(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
    child: child,
  );
}

/// Shell 顶层导航（Rail / drawer / 首页→历史·垃圾桶·管理等）：MD3 Top level fade-through。
Page<void> buildShellNavPage({
  required GoRouterState state,
  required Widget child,
}) {
  return buildDesktopFadeThroughPage(state: state, child: child);
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
          return SharedAxisTransitionWrapper(
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
