import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 同级内容切换：水平 Shared Axis（漫画↔系列、管理页作者/标签/原作/角色等对等分段）。
///
/// 与 [ListDetailDetailTransition] 同机制；语义上强调 peer / lateral，而非详情区。
///
/// [layoutBuilder] 顶部对齐，且仅由进入中的子组件决定高度，避免高度差大的
/// chip / 列表在默认居中 Stack 下过渡结束时上下跳动。
class PeerContentTransition extends StatelessWidget {
  const PeerContentTransition({
    super.key,
    required this.switchKey,
    required this.child,
    this.reverse = false,
  });

  final Object switchKey;
  final Widget child;

  /// 为 true 时表示退回（例如系列 → 漫画、标签 → 作者）。
  final bool reverse;

  static const Duration transitionDuration = kDesktopPageTransitionDuration;

  /// [PageTransitionSwitcher] 进入项下标：前进时新项在末尾；退回时插在倒数第二。
  @visibleForTesting
  static int incomingEntryIndex(int entryCount, {required bool reverse}) {
    if (entryCount <= 0) {
      return 0;
    }
    if (reverse && entryCount > 1) {
      return entryCount - 2;
    }
    return entryCount - 1;
  }

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
    final bool transitionReverse = reverse;

    return PageTransitionSwitcher(
      duration: duration,
      reverse: transitionReverse,
      layoutBuilder: (List<Widget> entries) {
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }
        final int incomingIndex = incomingEntryIndex(
          entries.length,
          reverse: transitionReverse,
        );
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            for (int i = 0; i < entries.length; i++)
              if (i == incomingIndex)
                entries[i]
              else
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: entries[i],
                ),
          ],
        );
      },
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
