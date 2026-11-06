import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Desktop route fade-through: old page fully out, then new page in (280ms total).
const Duration kDesktopPageTransitionDuration = Duration(milliseconds: 280);

/// Opacity while a route is entering (push forward, [t]: 0→1).
@visibleForTesting
double desktopFadeThroughEnterOpacity(double t) {
  if (t <= 0.5) {
    return 0.0;
  }
  return Curves.easeOutCubic.transform((t - 0.5) / 0.5);
}

/// Opacity while a route is exiting (pop reverse, [t]: 1→0).
@visibleForTesting
double desktopFadeThroughExitOpacity(double t) {
  if (t >= 0.5) {
    return 1.0;
  }
  return Curves.easeInCubic.transform(t / 0.5);
}

@visibleForTesting
double resolveDesktopFadeThroughOpacity({
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
}) {
  switch (animation.status) {
    case AnimationStatus.forward:
      return desktopFadeThroughEnterOpacity(animation.value);
    case AnimationStatus.reverse:
      return desktopFadeThroughExitOpacity(animation.value);
    case AnimationStatus.completed:
    case AnimationStatus.dismissed:
      break;
  }

  // 下方路由（如库浏览被 comic/series 详情 push 盖住）保持不透明。
  // 若对 secondary 做 fade-through，pop 中段 opacity=0 会露出壳层白底，
  // 而 NavigationRail 在 Shell 外不受 page 过渡影响，表现为「只有内容区闪白」。
  // Shell 顶层 go 切换只走上方 primary enter/exit，不依赖 secondary 淡出。
  if (animation.isCompleted && secondaryAnimation.value > 0) {
    return 1.0;
  }

  if (animation.isDismissed) {
    return 0.0;
  }
  return 1.0;
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

  return AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[animation, secondaryAnimation]),
    builder: (BuildContext context, Widget? builtChild) {
      final double opacity = resolveDesktopFadeThroughOpacity(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
      );
      return Opacity(opacity: opacity.clamp(0.0, 1.0), child: builtChild);
    },
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
