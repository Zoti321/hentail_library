import 'package:hentai_library/design-system/l10n/m3e_material_localizations.dart';
import 'package:hentai_library/design-system/motion/motion.dart';
import 'package:hentai_library/design-system/motion/spring_value.dart';
import 'package:hentai_library/design-system/components/calendar/calendar_month_picker.dart';
import 'package:hentai_library/design-system/components/calendar/calendar_year_picker.dart';
import 'package:material_3_expressive/components/date_pickers/components/m3e_date_picker_mode_toggle.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:flutter/material.dart' hide MaterialLocalizations;

/// 可嵌入表单的日历（与 [M3ECalendarDatePicker] 一致，年份模式使用 [CalendarYearPicker]）。
class EmbeddableCalendarDatePicker extends StatefulWidget {
  const EmbeddableCalendarDatePicker({
    required this.onDateChanged,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.currentDate,
    this.initialCalendarMode = M3EDatePickerMode.day,
    this.onDisplayedMonthChanged,
    this.onCalendarModeChanged,
    this.selectableDayPredicate,
    this.expandToFit = false,
    this.onDaySelected,
    super.key,
  });

  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? currentDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTime>? onDisplayedMonthChanged;
  final ValueChanged<M3EDatePickerMode>? onCalendarModeChanged;
  final M3EDatePickerMode initialCalendarMode;
  final M3ESelectableDayPredicate? selectableDayPredicate;
  final bool expandToFit;
  final ValueChanged<DateTime>? onDaySelected;

  @override
  State<EmbeddableCalendarDatePicker> createState() =>
      _EmbeddableCalendarDatePickerState();
}

class _EmbeddableCalendarDatePickerState
    extends State<EmbeddableCalendarDatePicker> {
  late M3EDatePickerMode _mode;
  late DateTime _displayedMonth;
  late DateTime _firstDate;
  late DateTime _lastDate;
  late DateTime _currentDate;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _firstDate = M3EDatePickerUtils.dateOnly(widget.firstDate);
    _lastDate = M3EDatePickerUtils.dateOnly(widget.lastDate);
    _currentDate = M3EDatePickerUtils.dateOnly(
      widget.currentDate ?? DateTime.now(),
    );
    _mode = widget.initialCalendarMode;
    _selectedDate = widget.initialDate == null
        ? null
        : M3EDatePickerUtils.dateOnly(widget.initialDate!);
    final DateTime base = _selectedDate ?? _currentDate;
    _displayedMonth = M3EDatePickerUtils.getMonth(base.year, base.month);
    assert(
      !_lastDate.isBefore(_firstDate),
      'lastDate must be on or after firstDate',
    );
  }

  void _handleModeChanged(M3EDatePickerMode mode) {
    M3EHaptics.selection();
    setState(() => _mode = mode);
    widget.onCalendarModeChanged?.call(mode);
  }

  void _handleMonthChanged(DateTime month) {
    setState(() => _displayedMonth = month);
    widget.onDisplayedMonthChanged?.call(month);
  }

  void _handleYearChanged(DateTime value) {
    M3EHaptics.selection();
    final DateTime clamped = M3EDatePickerUtils.clampDate(
      value,
      _firstDate,
      _lastDate,
    );
    setState(() {
      _mode = M3EDatePickerMode.day;
      _displayedMonth = M3EDatePickerUtils.getMonth(
        clamped.year,
        clamped.month,
      );
      if (M3EDatePickerUtils.isSelectable(
        clamped,
        _firstDate,
        _lastDate,
        predicate: widget.selectableDayPredicate,
      )) {
        _selectedDate = clamped;
        widget.onDateChanged(clamped);
      }
    });
    widget.onDisplayedMonthChanged?.call(_displayedMonth);
    widget.onCalendarModeChanged?.call(M3EDatePickerMode.day);
  }

  void _handleDayChanged(DateTime value) {
    M3EHaptics.selection();
    setState(() {
      _selectedDate = value;
      widget.onDateChanged(value);
    });
    widget.onDaySelected?.call(value);
  }

  double _inlinePickerBodyHeight(BuildContext context) {
    final int firstDayOfWeekIndex = materialLocalizationsOf(context)
        .firstDayOfWeekIndex;
    return switch (_mode) {
      M3EDatePickerMode.day => M3EDatePickerUtils.calendarDayViewHeight(
        _displayedMonth,
        firstDayOfWeekIndex,
      ),
      M3EDatePickerMode.year => calendarYearViewHeight(
        _firstDate,
        _lastDate,
        includeSubHeader: false,
      ),
    };
  }

  Widget _yearPicker() {
    return CalendarYearPicker(
      selectedDate: _selectedDate,
      firstDate: _firstDate,
      lastDate: _lastDate,
      onChanged: _handleYearChanged,
      selectableDayPredicate: widget.selectableDayPredicate,
      displayedMonth: _displayedMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return M3EComponentTheme(
      builder: (BuildContext context) {
        return materialUiLocalizationsScope(
          child: Builder(
            builder: (BuildContext scopedContext) {
              final M3EThemeData theme = M3ETheme.of(scopedContext);
              final M3EDatePickerTheme dateTheme = theme.datePickerTheme;

              if (widget.expandToFit) {
                final Widget picker = switch (_mode) {
                  M3EDatePickerMode.day => CalendarMonthPicker(
                    initialMonth: _displayedMonth,
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                    selectedDate: _selectedDate,
                    currentDate: _currentDate,
                    onChanged: _handleDayChanged,
                    onMonthChanged: _handleMonthChanged,
                    selectableDayPredicate: widget.selectableDayPredicate,
                    expandToFit: true,
                    mode: _mode,
                    onModeChanged: _handleModeChanged,
                  ),
                  M3EDatePickerMode.year => Padding(
                    padding: const EdgeInsets.only(
                      top: M3EDatePickerConstants.subHeaderHeight,
                    ),
                    child: _yearPicker(),
                  ),
                };
                return Stack(
                  children: <Widget>[
                    Positioned.fill(child: picker),
                    if (_mode == M3EDatePickerMode.year)
                      M3EDatePickerModeToggle(
                        mode: _mode,
                        monthDate: _displayedMonth,
                        onChanged: _handleModeChanged,
                      ),
                  ],
                );
              }

              final double bodyHeight = _inlinePickerBodyHeight(scopedContext);
              final Widget content = Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  M3EDatePickerModeToggle(
                    mode: _mode,
                    monthDate: _displayedMonth,
                    onChanged: _handleModeChanged,
                  ),
                  SpringValue(
                    value: bodyHeight,
                    motion: LabMotion.spatialReveal,
                    builder:
                        (BuildContext context, double height, Widget? child) {
                          return SizedBox(
                            height: height,
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minHeight: bodyHeight,
                                maxHeight: bodyHeight,
                                child: child,
                              ),
                            ),
                          );
                        },
                    child: SizedBox(
                      height: bodyHeight,
                      child: switch (_mode) {
                        M3EDatePickerMode.day => CalendarMonthPicker(
                          initialMonth: _displayedMonth,
                          firstDate: _firstDate,
                          lastDate: _lastDate,
                          selectedDate: _selectedDate,
                          currentDate: _currentDate,
                          onChanged: _handleDayChanged,
                          onMonthChanged: _handleMonthChanged,
                          selectableDayPredicate: widget.selectableDayPredicate,
                        ),
                        M3EDatePickerMode.year => _yearPicker(),
                      },
                    ),
                  ),
                ],
              );

              return Container(
                width: dateTheme.width,
                padding: dateTheme.padding,
                decoration: BoxDecoration(
                  color: dateTheme.containerColor(theme.colorScheme),
                  borderRadius: dateTheme.borderRadius,
                ),
                child: content,
              );
            },
          ),
        );
      },
    );
  }
}
