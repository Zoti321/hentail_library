import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../motion/motion.dart';
import 'calendar_date_grid.dart';
import 'calendar_navigation.dart';
import 'calendar_size_transition.dart';
import 'calendar_selection_menu.dart';

enum _CalendarView { days, months, years }

/// The calendar body shared by docked and modal single-date pickers.
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
    this.onDateSubmitted,
    this.modal = false,
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
  final bool Function(DateTime)? selectableDayPredicate;
  final bool expandToFit;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onDateSubmitted;
  final bool modal;

  @override
  State<EmbeddableCalendarDatePicker> createState() =>
      _EmbeddableCalendarDatePickerState();
}

class _EmbeddableCalendarDatePickerState
    extends State<EmbeddableCalendarDatePicker> {
  late DateTime _month;
  late DateTime _focusedDate;
  late _CalendarView _view;
  DateTime? _selected;
  final _gridFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();

  DateTime get _first => DateUtils.dateOnly(widget.firstDate);
  DateTime get _last => DateUtils.dateOnly(widget.lastDate);

  DateTime _clamp(DateTime value) => value.isBefore(_first)
      ? _first
      : value.isAfter(_last)
      ? _last
      : value;

  @override
  void initState() {
    super.initState();
    assert(!_last.isBefore(_first));
    _selected = widget.initialDate == null
        ? null
        : DateUtils.dateOnly(widget.initialDate!);
    _focusedDate = _clamp(_selected ?? widget.currentDate ?? DateTime.now());
    _month = DateTime(_focusedDate.year, _focusedDate.month);
    _view = widget.initialCalendarMode == M3EDatePickerMode.year
        ? _CalendarView.years
        : _CalendarView.days;
  }

  @override
  void didUpdateWidget(covariant EmbeddableCalendarDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate ||
        widget.firstDate != oldWidget.firstDate ||
        widget.lastDate != oldWidget.lastDate) {
      _selected = widget.initialDate == null
          ? null
          : DateUtils.dateOnly(widget.initialDate!);
      _focusedDate = _clamp(_selected ?? _focusedDate);
      _month = DateTime(_focusedDate.year, _focusedDate.month);
    }
  }

  @override
  void dispose() {
    _gridFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  void _navigate(DateTime month) {
    final clamped = _clamp(month);
    setState(() {
      _month = DateTime(clamped.year, clamped.month);
      _focusedDate = _clamp(
        DateTime(
          _month.year,
          _month.month,
          _focusedDate.day.clamp(
            1,
            DateUtils.getDaysInMonth(_month.year, _month.month),
          ),
        ),
      );
    });
    widget.onDisplayedMonthChanged?.call(_month);
  }

  void _show(_CalendarView view) {
    setState(() => _view = _view == view ? _CalendarView.days : view);
    widget.onCalendarModeChanged?.call(
      _view == _CalendarView.years
          ? M3EDatePickerMode.year
          : M3EDatePickerMode.day,
    );
  }

  bool _enabled(DateTime day) =>
      !day.isBefore(_first) &&
      !day.isAfter(_last) &&
      (widget.selectableDayPredicate?.call(day) ?? true);

  void _select(DateTime day) {
    if (!_enabled(day)) return;
    setState(() {
      _selected = day;
      _focusedDate = day;
    });
    widget.onDateChanged(day);
    widget.onDaySelected?.call(day);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (shift && key == LogicalKeyboardKey.keyM && !widget.modal) {
      _show(_CalendarView.months);
      _monthFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (shift && key == LogicalKeyboardKey.keyY) {
      _show(_CalendarView.years);
      _yearFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (!_gridFocus.hasFocus || _view != _CalendarView.days) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _select(_focusedDate);
      widget.onDateSubmitted?.call(_focusedDate);
      return KeyEventResult.handled;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    DateTime? target;
    if (key == LogicalKeyboardKey.arrowLeft) {
      target = DateUtils.addDaysToDate(_focusedDate, rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      target = DateUtils.addDaysToDate(_focusedDate, rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      target = DateUtils.addDaysToDate(_focusedDate, -7);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      target = DateUtils.addDaysToDate(_focusedDate, 7);
    } else if (key == LogicalKeyboardKey.home) {
      target = DateTime(_month.year, _month.month);
    } else if (key == LogicalKeyboardKey.end) {
      target = DateTime(_month.year, _month.month + 1, 0);
    } else if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final delta = key == LogicalKeyboardKey.pageUp ? -1 : 1;
      final month = DateTime(
        _month.year,
        _month.month + delta * (shift ? 12 : 1),
      );
      target = DateTime(
        month.year,
        month.month,
        _focusedDate.day.clamp(
          1,
          DateUtils.getDaysInMonth(month.year, month.month),
        ),
      );
    }
    if (target == null) return KeyEventResult.ignored;
    var candidate = _clamp(target);
    final step = candidate.isBefore(_focusedDate) ? -1 : 1;
    while (!_enabled(candidate) &&
        candidate.isAfter(_first) &&
        candidate.isBefore(_last)) {
      candidate = DateUtils.addDaysToDate(candidate, step);
    }
    if (_enabled(candidate)) {
      _navigate(candidate);
      setState(() => _focusedDate = candidate);
    }
    return KeyEventResult.handled;
  }

  void _choose(int value) {
    _navigate(
      _view == _CalendarView.months
          ? DateTime(_month.year, value)
          : DateTime(value, _month.month),
    );
    _show(_view);
    _gridFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colors = Theme.of(context).colorScheme;
    final duration = LabMotion.motionDurationOf(
      context,
      LabMotion.durationShort,
    );
    final monthName = DateFormat.MMM(locale).format(_month);
    final yearName = l10n.formatYear(_month);
    final previous = DateTime(_month.year, _month.month - 1);
    final next = DateTime(_month.year, _month.month + 1);
    final navigation = Row(
      children: [
        if (!widget.modal)
          Expanded(
            child: CalendarNavigation(
              label: monthName,
              menuKey: const ValueKey('calendar-month-menu'),
              focusNode: _monthFocus,
              active: _view == _CalendarView.months,
              enabled: _view != _CalendarView.years,
              showArrows: _view == _CalendarView.days,
              previousLabel: '${l10n.previousMonthTooltip} (Page Up)',
              nextLabel: '${l10n.nextMonthTooltip} (Page Down)',
              menuHint: '${l10n.formatMonthYear(_month)} (Shift+M)',
              onPrevious: previous.isBefore(DateTime(_first.year, _first.month))
                  ? null
                  : () => _navigate(previous),
              onNext: next.isAfter(_last) ? null : () => _navigate(next),
              onMenu: () => _show(_CalendarView.months),
            ),
          ),
        Expanded(
          child: CalendarNavigation(
            label: widget.modal ? l10n.formatMonthYear(_month) : yearName,
            menuKey: const ValueKey('calendar-year-menu'),
            focusNode: _yearFocus,
            active: _view == _CalendarView.years,
            enabled: _view != _CalendarView.months,
            showArrows: _view == _CalendarView.days,
            previousLabel: widget.modal
                ? l10n.previousMonthTooltip
                : '${l10n.previousPageTooltip}, ${l10n.formatYear(DateTime(_month.year - 1))} (Shift+Page Up)',
            nextLabel: widget.modal
                ? l10n.nextMonthTooltip
                : '${l10n.nextPageTooltip}, ${l10n.formatYear(DateTime(_month.year + 1))} (Shift+Page Down)',
            menuHint: '${l10n.selectYearSemanticsLabel} (Shift+Y)',
            trailingArrows: widget.modal,
            onPrevious: widget.modal
                ? (previous.isBefore(DateTime(_first.year, _first.month))
                      ? null
                      : () => _navigate(previous))
                : (_month.year <= _first.year
                      ? null
                      : () =>
                            _navigate(DateTime(_month.year - 1, _month.month))),
            onNext: widget.modal
                ? (next.isAfter(_last) ? null : () => _navigate(next))
                : (_month.year >= _last.year
                      ? null
                      : () =>
                            _navigate(DateTime(_month.year + 1, _month.month))),
            onMenu: () => _show(_CalendarView.years),
          ),
        ),
      ],
    );
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final rowHeight = 48.0 * textScale.clamp(1.0, 2.0);
    final offset = DateUtils.firstDayOffset(_month.year, _month.month, l10n);
    final rows = widget.modal
        ? 6
        : ((offset + DateUtils.getDaysInMonth(_month.year, _month.month)) / 7)
              .ceil();
    final body = _view == _CalendarView.days
        ? CalendarDateGrid(
            key: ValueKey(_month),
            month: _month,
            rows: rows,
            rowHeight: rowHeight,
            selected: _selected,
            today: widget.currentDate ?? DateTime.now(),
            focusedDate: _focusedDate,
            focusNode: _gridFocus,
            showOutsideMonth: !widget.modal,
            enabled: _enabled,
            onSelected: _select,
            onSwipe: widget.modal
                ? (delta) =>
                      _navigate(DateTime(_month.year, _month.month + delta))
                : null,
          )
        : SizedBox(
            height: rowHeight * (widget.modal ? 7 : 6),
            child: CalendarSelectionMenu(
              key: ValueKey(_view),
              months: _view == _CalendarView.months,
              year: _month.year,
              firstDate: _first,
              lastDate: _last,
              selected: _view == _CalendarView.months
                  ? _month.month
                  : _month.year,
              columns: widget.modal ? 3 : 1,
              rowHeight: rowHeight,
              onSelected: _choose,
            ),
          );

    return Focus(
      onKeyEvent: _key,
      child: Container(
        width: widget.expandToFit ? double.infinity : 360,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(widget.modal ? 28 : 16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            navigation,
            if (_view != _CalendarView.days)
              Divider(height: 16, color: colors.outlineVariant),
            CalendarSizeTransition(
              duration: duration,
              curve: LabMotion.curveEmphasized,
              alignment: Alignment.topCenter,
              child: TweenAnimationBuilder<double>(
                key: ValueKey((_month, _view)),
                tween: Tween(begin: 0, end: 1),
                duration: duration,
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
