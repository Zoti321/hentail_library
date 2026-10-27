import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Single page number control in the standard pagination strip.
class Md3ePaginationPageButton extends StatelessWidget {
  const Md3ePaginationPageButton({
    super.key,
    required this.page,
    required this.selected,
    required this.onPressed,
    this.showSelectionFill = true,
  });

  final int page;
  final bool selected;
  final VoidCallback? onPressed;

  /// When false, selection is drawn by [Md3ePaginationStandardPageStrip].
  final bool showSelectionFill;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETabTheme tabTheme = theme.tabTheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    final Duration duration = Md3eMotion.motionDurationOf(
      context,
      Md3eMotion.durationShort,
    );
    final Curve enterCurve = Md3eMotion.curveForStateEnter(
      reduceMotion: reduceMotion,
    );
    final Curve exitCurve = Md3eMotion.curveForStateExit(
      reduceMotion: reduceMotion,
    );

    return SizedBox(
      width: Md3ePaginationMetrics.pageButtonSlotWidth,
      height: Md3ePaginationMetrics.pageButtonSlotWidth,
      child: M3ETappable(
        onTap: onPressed,
        enabled: onPressed != null,
        semanticLabel: context.l10n.md3ePaginationPageSemantic(page),
        builder: (BuildContext context, M3EInteractionState state) {
          final double stateAlpha = tabTheme.stateOpacity(
            hovered: state.hovered,
            focused: state.focused,
            pressed: state.pressed,
          );
          final Color stateColor = tabTheme.stateLayerColor(
            scheme,
            variant: M3ETabsVariant.primary,
            selected: selected,
          );
          final Color? fill = showSelectionFill && selected
              ? scheme.primaryContainer
              : stateAlpha > 0
              ? stateColor.withValues(alpha: stateAlpha)
              : null;

          final TextStyle? labelStyle = textTheme.labelLarge?.copyWith(
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          );

          return Center(
            child: AnimatedContainer(
              duration: duration,
              curve: selected ? enterCurve : exitCurve,
              width: Md3ePaginationMetrics.pageButtonVisualSize,
              height: Md3ePaginationMetrics.pageButtonVisualSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$page', style: labelStyle),
            ),
          );
        },
      ),
    );
  }
}

/// Ellipsis slot matching [Md3ePaginationPageButton] footprint.
class Md3ePaginationEllipsisSlot extends StatelessWidget {
  const Md3ePaginationEllipsisSlot({super.key, required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Md3ePaginationMetrics.pageButtonSlotWidth,
      height: Md3ePaginationMetrics.pageButtonSlotWidth,
      child: Center(child: Text('…', style: style)),
    );
  }
}

/// Invisible slot reserved for stable strip width.
class Md3ePaginationEmptySlot extends StatelessWidget {
  const Md3ePaginationEmptySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Md3ePaginationMetrics.pageButtonSlotWidth,
      height: Md3ePaginationMetrics.pageButtonSlotWidth,
    );
  }
}
