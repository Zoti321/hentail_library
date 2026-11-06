import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';

/// List-detail **详情区**切换：官方 [PageTransitionSwitcher] + [FadeThroughTransition]。
///
/// 对齐 MD3 Top level / Clean fades 与 Material motion Codelab，避免
/// [AnimatedSwitcher] 双 Controller 交叉淡入造成的文字叠影。
class ListDetailDetailTransition extends StatelessWidget {
  const ListDetailDetailTransition({
    super.key,
    required this.switchKey,
    required this.child,
  });

  final Object switchKey;
  final Widget child;

  static const Duration transitionDuration = kDesktopPageTransitionDuration;

  @override
  Widget build(BuildContext context) {
    if (LabMotion.reduceMotionOf(context)) {
      return child;
    }

    final Duration duration = LabMotion.motionDurationOf(
      context,
      transitionDuration,
    );

    return PageTransitionSwitcher(
      duration: duration,
      transitionBuilder:
          (
            Widget child,
            Animation<double> primary,
            Animation<double> secondary,
          ) {
            return FadeThroughTransition(
              animation: primary,
              secondaryAnimation: secondary,
              fillColor: Theme.of(context).colorScheme.surface,
              child: child,
            );
          },
      child: KeyedSubtree(key: ValueKey<Object>(switchKey), child: child),
    );
  }
}
