import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Desktop route fade-through: old page fully out, then new page in (280ms total).
const Duration kDesktopPageTransitionDuration = Duration(milliseconds: 280);

/// Tracks whether the active navigator transition is a pop (vs push/replace).
///
/// Used to pick covered vs uncovered opacity when [ModalRoute.animation] is idle
/// but [ModalRoute.secondaryAnimation] is running on the route below.
final DesktopPageTransitionObserver desktopPageTransitionObserver =
    DesktopPageTransitionObserver();

class DesktopPageTransitionObserver extends NavigatorObserver {
  bool lastTransitionWasPop = false;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastTransitionWasPop = true;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastTransitionWasPop = false;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastTransitionWasPop = false;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    lastTransitionWasPop = false;
  }
}

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

/// Opacity for a route being covered by a push ([t]: secondary 0→1).
@visibleForTesting
double desktopFadeThroughCoveredOpacity(double t) {
  if (t >= 0.5) {
    return 0.0;
  }
  return 1.0 - Curves.easeInCubic.transform(t / 0.5);
}

/// Opacity for a route revealed after a pop ([t]: secondary 0→1).
@visibleForTesting
double desktopFadeThroughUncoveredOpacity(double t) {
  if (t <= 0.5) {
    return 0.0;
  }
  return Curves.easeOutCubic.transform((t - 0.5) / 0.5);
}

@visibleForTesting
double resolveDesktopFadeThroughOpacity({
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required bool revealingFromPop,
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

  if (animation.isCompleted && secondaryAnimation.value > 0) {
    if (revealingFromPop) {
      return desktopFadeThroughUncoveredOpacity(secondaryAnimation.value);
    }
    return desktopFadeThroughCoveredOpacity(secondaryAnimation.value);
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
        revealingFromPop: desktopPageTransitionObserver.lastTransitionWasPop,
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

/// Shell top-level nav (sidebar / drawer): instant swap, no page transition.
NoTransitionPage<void> buildShellNavPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
  );
}
