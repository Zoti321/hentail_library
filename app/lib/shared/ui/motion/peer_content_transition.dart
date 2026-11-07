import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 同级内容切换：水平 Shared Axis（漫画↔系列、对等分段视图）。
///
/// 与 [ListDetailDetailTransition] 同机制；语义上强调 peer / lateral，而非详情区。
class PeerContentTransition extends StatelessWidget {
  const PeerContentTransition({
    super.key,
    required this.switchKey,
    required this.child,
    this.reverse = false,
  });

  final Object switchKey;
  final Widget child;

  /// 为 true 时表示退回（例如系列 → 漫画）。
  final bool reverse;

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
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: fillColor,
              child: child,
            );
          },
      child: KeyedSubtree(key: ValueKey<Object>(switchKey), child: child),
    );
  }
}
