import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/motion/motion.dart';
import 'package:hentai_library/design-system/theme/color/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 浏览/多选等页头 chrome 切换：垂直 Shared Axis。
///
/// [reverse] 为 true 时表示退回（例如退出多选），与前进方向相反。
class ModeChromeTransition extends StatelessWidget {
  const ModeChromeTransition({
    super.key,
    required this.switchKey,
    required this.child,
    this.reverse = false,
  });

  final Object switchKey;
  final Widget child;
  final bool reverse;

  static const Duration transitionDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    if (LabMotion.reduceMotionOf(context)) {
      return child;
    }

    final Duration duration = LabMotion.motionDurationOf(
      context,
      transitionDuration,
    );
    final Color fillColor = labBrowseCanvasColor(
      M3ETheme.of(context).colorScheme,
    );

    return PageTransitionSwitcher(
      duration: duration,
      reverse: reverse,
      transitionBuilder:
          (
            Widget child,
            Animation<double> primary,
            Animation<double> secondary,
          ) {
            return SharedAxisTransition(
              animation: primary,
              secondaryAnimation: secondary,
              transitionType: SharedAxisTransitionType.vertical,
              fillColor: fillColor,
              child: child,
            );
          },
      child: KeyedSubtree(key: ValueKey<Object>(switchKey), child: child),
    );
  }
}
