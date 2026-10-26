import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_motion.dart';

/// Animated "current / total" label for [Md3ePaginationCompact].
class Md3ePaginationCompactSummary extends StatelessWidget {
  const Md3ePaginationCompactSummary({
    super.key,
    required this.page,
    required this.totalPages,
    required this.style,
  });

  final int page;
  final int totalPages;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final Duration duration = Md3ePaginationMotion.motionDuration(context);
    final bool reduceMotion = duration == Duration.zero;

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: Md3ePaginationMotion.pageChangeCurve(
        reduceMotion: reduceMotion,
      ),
      switchOutCurve: Md3ePaginationMotion.pageChangeExitCurve(
        reduceMotion: reduceMotion,
      ),
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Md3ePaginationMotion.pageChangeCurve(
            reduceMotion: reduceMotion,
          ),
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Md3ePaginationMotion.compactSummarySlideBegin,
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: Text(
        key: ValueKey<int>(page),
        '$page / $totalPages',
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
