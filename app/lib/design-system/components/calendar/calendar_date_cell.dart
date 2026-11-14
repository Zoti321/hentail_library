import 'package:flutter/material.dart';

class CalendarDateCell extends StatelessWidget {
  const CalendarDateCell({
    required this.day,
    required this.month,
    required this.selected,
    required this.today,
    required this.focused,
    required this.focusedDate,
    required this.showOutsideMonth,
    required this.enabled,
    required this.onSelected,
    super.key,
  });
  final DateTime day;
  final DateTime month;
  final DateTime? selected;
  final DateTime today;
  final bool focused;
  final DateTime focusedDate;
  final bool showOutsideMonth;
  final bool Function(DateTime) enabled;
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) {
    final outside = day.month != month.month;
    if (outside && !showOutsideMonth) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final l10n = MaterialLocalizations.of(context);
    // Outside-month cells provide context; navigation remains explicit.
    final active = !outside && enabled(day);
    final isSelected = active && DateUtils.isSameDay(day, selected);
    final isToday = DateUtils.isSameDay(day, today);
    final isFocused = focused && DateUtils.isSameDay(day, focusedDate);
    final stateColor = isSelected ? colors.onPrimary : colors.onSurfaceVariant;
    final baseColor = isSelected ? colors.primary : colors.surfaceContainerHigh;
    final foreground = !active
        ? colors.onSurface.withValues(alpha: 0.38)
        : isSelected
        ? colors.onPrimary
        : isToday
        ? colors.primary
        : colors.onSurface;
    return Semantics(
      key: ValueKey('calendar-date-${day.toIso8601String().split('T').first}'),
      button: true,
      enabled: active,
      selected: isSelected,
      focused: isFocused,
      focusable: active,
      label: isToday
          ? '${l10n.formatFullDate(day)}, ${l10n.currentDateLabel}'
          : l10n.formatFullDate(day),
      onTap: active ? () => onSelected(day) : null,
      excludeSemantics: true,
      // Keep ink above the calendar body's opaque surface decoration.
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          canRequestFocus: false,
          onTap: active ? () => onSelected(day) : null,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          radius: 24,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (!active) return Colors.transparent;
            if (states.contains(WidgetState.pressed)) {
              return stateColor.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered) && !isFocused) {
              return stateColor.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          child: Center(
            // Ink decoration lets hover and ripple paint above the selected fill.
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active && isFocused
                    ? Color.alphaBlend(
                        stateColor.withValues(alpha: 0.1),
                        baseColor,
                      )
                    : isSelected
                    ? colors.primary
                    : null,
                border: isToday || isFocused
                    ? Border.all(
                        color: colors.primary,
                        width: isFocused ? 2 : 1,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  l10n.formatDecimal(day.day),
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
