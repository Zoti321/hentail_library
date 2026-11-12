import 'package:flutter/material.dart';

import '../../l10n/design_system_localizations.dart';
import 'pagination_metrics.dart';
import 'pagination_standard_page_strip.dart';
import '../../motion/effects_decorated_box.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

/// Single page number control in the standard pagination strip.
class PaginationPageButton extends StatelessWidget {
  const PaginationPageButton({
    super.key,
    required this.page,
    required this.selected,
    required this.onPressed,
    this.showSelectionFill = true,
  });

  final int page;
  final bool selected;
  final VoidCallback? onPressed;

  /// When false, selection is drawn by [PaginationStandardPageStrip].
  final bool showSelectionFill;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETabTheme tabTheme = theme.tabTheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: PaginationMetrics.pageButtonSlotWidth,
      height: PaginationMetrics.pageButtonSlotWidth,
      child: M3ETappable(
        onTap: onPressed,
        enabled: onPressed != null,
        semanticLabel: DesignSystemLocalizations.of(context).pageSemantic(page),
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
            child: EffectsDecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: SizedBox(
                width: PaginationMetrics.pageButtonVisualSize,
                height: PaginationMetrics.pageButtonVisualSize,
                child: Center(child: Text('$page', style: labelStyle)),
              ),
            ),
          );
        },
      ),
    );
  }
}
