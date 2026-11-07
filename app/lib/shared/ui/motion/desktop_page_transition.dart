import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Desktop / shell top-level fade-through（对齐官方 animations FadeThrough）。
const Duration kDesktopPageTransitionDuration = Duration(milliseconds: 280);

/// 官方 FadeThrough 进场透明度分界（前 6/20 保持 0）。
@visibleForTesting
const double kFadeThroughIncomingStart = 6 / 20;

/// 官方 FadeThrough 退场透明度分界（前 6/20 淡到 0）。
@visibleForTesting
const double kFadeThroughOutgoingEnd = 6 / 20;

/// 与 animations `_ZoomedFadeIn` 进场 opacity 同权重：前 6/20 为 0，其后淡入。
@visibleForTesting
double desktopFadeThroughEnterOpacity(double t) {
  if (t <= kFadeThroughIncomingStart) {
    return 0.0;
  }
  if (t >= 1.0) {
    return 1.0;
  }
  final double local =
      (t - kFadeThroughIncomingStart) / (1.0 - kFadeThroughIncomingStart);
  return const Cubic(0.0, 0.0, 0.2, 1.0).transform(local.clamp(0.0, 1.0));
}

/// 与 animations `_FadeOut` 退场 opacity 同权重：前 6/20 淡到 0，其后保持 0。
///
/// [t] 为 **forward** 进度（0→1 表示正在退场），不是 ReverseAnimation 的值。
@visibleForTesting
double desktopFadeThroughExitOpacity(double t) {
  if (t <= 0.0) {
    return 1.0;
  }
  if (t >= kFadeThroughOutgoingEnd) {
    return 0.0;
  }
  final double local = t / kFadeThroughOutgoingEnd;
  return 1.0 - const Cubic(0.4, 0.0, 1.0, 1.0).transform(local.clamp(0.0, 1.0));
}

Widget desktopFadeThroughTransitionWrapper({
  required BuildContext context,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
}) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return child;
  }

  // secondary 停住：库浏览被详情 push 盖住时不淡出下方页，避免 pop 中段闪白。
  // Shell 顶层 go 切换只依赖各页自己的 primary FadeThrough。
  // fillColor 与壳层画布一致，避免透明页被 Theme.surface 盖成另一套底色。
  return FadeThroughTransition(
    animation: animation,
    secondaryAnimation: const AlwaysStoppedAnimation<double>(0),
    fillColor: labBrowseCanvasColor(M3ETheme.of(context).colorScheme),
    child: child,
  );
}

/// [PageTransitionsTheme] builder for desktop OS targets.
class DesktopFadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const DesktopFadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return desktopFadeThroughTransitionWrapper(
      context: context,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
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
          return desktopFadeThroughTransitionWrapper(
            context: context,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
    child: child,
  );
}

/// Shell 顶层导航（Rail / drawer / 首页→历史·垃圾桶等）：MD3 Top level fade-through。
Page<void> buildShellNavPage({
  required GoRouterState state,
  required Widget child,
}) {
  return buildDesktopFadeThroughPage(state: state, child: child);
}
