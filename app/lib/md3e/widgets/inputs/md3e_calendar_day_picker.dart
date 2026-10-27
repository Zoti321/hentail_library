import 'package:hentai_library/md3e/widgets/inputs/md3e_calendar_day_cell.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// 月历日网格（使用 [Md3eCalendarDayCell]）。
class Md3eCalendarDayPicker extends StatelessWidget {
  const Md3eCalendarDayPicker({
    required this.displayedMonth,
    required this.selectedDate,
    required this.currentDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.selectableDayPredicate,
    this.rangeStart,
    this.rangeEnd,
    this.fitHeight = false,
    super.key,
  });

  final DateTime displayedMonth;
  final DateTime? selectedDate;
  final DateTime currentDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool Function(DateTime day)? selectableDayPredicate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final bool fitHeight;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EDatePickerTheme dateTheme = theme.datePickerTheme;
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final int year = displayedMonth.year;
    final int month = displayedMonth.month;
    final int daysInMonth = M3EDatePickerUtils.daysInMonth(year, month);
    final int firstDayOffset =
        (DateTime(year, month).weekday - localizations.firstDayOfWeekIndex) % 7;
    final int cellCount =
        ((daysInMonth + firstDayOffset) / dateTheme.daysPerWeek).ceil() *
        dateTheme.daysPerWeek;
    final int rowCount =
        ((daysInMonth + firstDayOffset) / dateTheme.daysPerWeek).ceil();

    if (fitHeight) {
      return Column(
        children: <Widget>[
          _buildWeekdayHeader(theme, dateTheme, localizations),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double rowHeight =
                    (constraints.maxHeight - dateTheme.gridPadding.vertical) /
                    rowCount;
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: dateTheme.gridPadding,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: rowHeight.clamp(
                      0.0,
                      M3EDatePickerConstants.dayPickerRowHeight,
                    ),
                  ),
                  itemCount: cellCount,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildDayCell(
                      index: index,
                      firstDayOffset: firstDayOffset,
                      daysInMonth: daysInMonth,
                      year: year,
                      month: month,
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildWeekdayHeader(theme, dateTheme, localizations),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: dateTheme.gridPadding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: M3EDatePickerConstants.dayPickerRowHeight,
          ),
          itemCount: cellCount,
          itemBuilder: (BuildContext context, int index) {
            return _buildDayCell(
              index: index,
              firstDayOffset: firstDayOffset,
              daysInMonth: daysInMonth,
              year: year,
              month: month,
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(
    M3EThemeData theme,
    M3EDatePickerTheme dateTheme,
    MaterialLocalizations localizations,
  ) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < dateTheme.daysPerWeek; i++)
          Expanded(
            child: Center(
              child: Text(
                localizations
                    .narrowWeekdays[(localizations.firstDayOfWeekIndex + i) %
                    7],
                style: dateTheme.weekdayStyle(
                  theme.typeScale,
                  theme.colorScheme,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell({
    required int index,
    required int firstDayOffset,
    required int daysInMonth,
    required int year,
    required int month,
  }) {
    final int day = index - firstDayOffset + 1;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox.shrink();
    }
    final DateTime date = DateTime(year, month, day);
    final bool enabled = M3EDatePickerUtils.isSelectable(
      date,
      firstDate,
      lastDate,
      predicate: selectableDayPredicate,
    );
    final DateTime? start = rangeStart;
    final DateTime? end = rangeEnd;
    return Md3eCalendarDayCell(
      date: date,
      selected: M3EDatePickerUtils.isSameDay(date, selectedDate),
      today: M3EDatePickerUtils.isSameDay(date, currentDate),
      enabled: enabled,
      inRange:
          start != null &&
          end != null &&
          M3EDatePickerUtils.isInRange(date, start, end),
      rangeStart: start != null && M3EDatePickerUtils.isSameDay(date, start),
      rangeEnd: end != null && M3EDatePickerUtils.isSameDay(date, end),
      onTap: enabled ? () => onChanged(date) : null,
    );
  }
}
