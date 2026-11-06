import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// List-detail **详情区**切换：水平 Shared Axis（对齐 Kazumi 设置内嵌水平过渡）。
///
/// 使用 [PageTransitionSwitcher] + [SharedAxisTransition]，避免 [AnimatedSwitcher]
/// 交叉淡入叠字；[fillColor] 与壳层画布 [labBrowseCanvasColor] 一致。
class ListDetailDetailTransition extends StatelessWidget {
  const ListDetailDetailTransition({
    super.key,
    required this.switchKey,
    required this.child,
    this.reverse = false,
  });

  final Object switchKey;
  final Widget child;

  /// 为 true 时向左退回（选中更靠前的 list 项）。
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
