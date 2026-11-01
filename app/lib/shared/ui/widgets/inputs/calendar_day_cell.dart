import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 月历日格：在 M3E 日格基础上为圆形选中区绘制 state layer。
class Md3eCalendarDayCell extends StatelessWidget {
  const Md3eCalendarDayCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.enabled,
    required this.onTap,
    this.inRange = false,
    this.rangeStart = false,
    this.rangeEnd = false,
    super.key,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final bool enabled;
  final VoidCallback? onTap;
  final bool inRange;
  final bool rangeStart;
  final bool rangeEnd;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3EDatePickerTheme dateTheme = theme.datePickerTheme;
    final Color foreground = dateTheme.dayForegroundColor(
      scheme,
      selected: selected || rangeStart || rangeEnd,
      enabled: enabled,
    );
    final bool showCaps = rangeStart || rangeEnd;
    final bool showRangeFill = inRange && !showCaps;
    final bool filled = selected || showCaps;

    return M3ETappable(
      enabled: enabled,
      onTap: onTap,
      semanticLabel: '${date.day}',
      builder: (BuildContext context, M3EInteractionState state) {
        final Color stateBase = filled ? scheme.onPrimary : scheme.onSurface;
        final double stateAlpha = enabled ? state.opacity : 0;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (showRangeFill)
              Positioned.fill(
                child: ColoredBox(color: dateTheme.rangeHighlightColor(scheme)),
              ),
            if (rangeStart && inRange)
              Positioned(
                left: dateTheme.daySize / 2,
                right: 0,
                top: (48 - dateTheme.daySize) / 2,
                bottom: (48 - dateTheme.daySize) / 2,
                child: ColoredBox(color: dateTheme.rangeHighlightColor(scheme)),
              ),
            if (rangeEnd && inRange)
              Positioned(
                left: 0,
                right: dateTheme.daySize / 2,
                top: (48 - dateTheme.daySize) / 2,
                bottom: (48 - dateTheme.daySize) / 2,
                child: ColoredBox(color: dateTheme.rangeHighlightColor(scheme)),
              ),
            Container(
              width: dateTheme.daySize,
              height: dateTheme.daySize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? dateTheme.selectedDayBackgroundColor(scheme)
                    : null,
                border: today && !selected && !showCaps
                    ? Border.all(color: dateTheme.todayColor(scheme))
                    : null,
              ),
              foregroundDecoration: stateAlpha > 0
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: stateBase.withValues(alpha: stateAlpha),
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: dateTheme
                    .dayStyle(theme.typeScale, scheme)
                    .copyWith(color: foreground),
              ),
            ),
          ],
        );
      },
    );
  }
}
