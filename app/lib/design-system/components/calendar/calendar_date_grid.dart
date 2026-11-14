import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'calendar_date_cell.dart';

/// Calendar table with one keyboard tab stop and complete cell semantics.
class CalendarDateGrid extends StatelessWidget {
  const CalendarDateGrid({
    required this.month,
    required this.rows,
    required this.rowHeight,
    required this.selected,
    required this.today,
    required this.focusedDate,
    required this.focusNode,
    required this.showOutsideMonth,
    required this.enabled,
    required this.onSelected,
    this.onSwipe,
    super.key,
  });
  final DateTime month;
  final int rows;
  final double rowHeight;
  final DateTime? selected;
  final DateTime today;
  final DateTime focusedDate;
  final FocusNode focusNode;
  final bool showOutsideMonth;
  final bool Function(DateTime) enabled;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<int>? onSwipe;

  void _select(DateTime day) {
    focusNode.requestFocus();
    onSelected(day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final offset = DateUtils.firstDayOffset(month.year, month.month, l10n);
    return GestureDetector(
      onHorizontalDragEnd: onSwipe == null
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() > 100) {
                final rtl = Directionality.of(context) == TextDirection.rtl;
                onSwipe!((velocity < 0) != rtl ? 1 : -1);
              }
            },
      child: Focus(
        key: const ValueKey('calendar-day-grid'),
        autofocus: true,
        focusNode: focusNode,
        child: ListenableBuilder(
          listenable: focusNode,
          builder: (context, child) => Table(
            children: [
              TableRow(
                children: [
                  for (var i = 0; i < 7; i++)
                    Tooltip(
                      message: DateFormat.EEEE(locale).format(
                        DateTime(
                          2024,
                          1,
                          7 + (i + l10n.firstDayOfWeekIndex) % 7,
                        ),
                      ),
                      child: Semantics(
                        role: ui.SemanticsRole.columnHeader,
                        label: DateFormat.EEEE(locale).format(
                          DateTime(
                            2024,
                            1,
                            7 + (i + l10n.firstDayOfWeekIndex) % 7,
                          ),
                        ),
                        excludeSemantics: true,
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              l10n.narrowWeekdays[(i +
                                      l10n.firstDayOfWeekIndex) %
                                  7],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (var row = 0; row < rows; row++)
                TableRow(
                  children: [
                    for (var column = 0; column < 7; column++)
                      SizedBox(
                        height: rowHeight,
                        child: CalendarDateCell(
                          day: DateTime(
                            month.year,
                            month.month,
                            row * 7 + column - offset + 1,
                          ),
                          month: month,
                          selected: selected,
                          today: today,
                          focused: focusNode.hasFocus,
                          focusedDate: focusedDate,
                          showOutsideMonth: showOutsideMonth,
                          enabled: enabled,
                          onSelected: _select,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
