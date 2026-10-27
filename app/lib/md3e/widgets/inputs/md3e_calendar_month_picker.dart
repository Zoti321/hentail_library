import 'package:flutter/services.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_calendar_day_picker.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// 月历翻页（使用 [Md3eCalendarDayPicker]）。
class Md3eCalendarMonthPicker extends StatefulWidget {
  const Md3eCalendarMonthPicker({
    required this.initialMonth,
    required this.firstDate,
    required this.lastDate,
    required this.selectedDate,
    required this.currentDate,
    required this.onChanged,
    required this.onMonthChanged,
    this.selectableDayPredicate,
    this.rangeStart,
    this.rangeEnd,
    this.expandToFit = false,
    this.mode,
    this.onModeChanged,
    super.key,
  });

  final DateTime initialMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedDate;
  final DateTime currentDate;
  final ValueChanged<DateTime> onChanged;
  final ValueChanged<DateTime> onMonthChanged;
  final bool Function(DateTime day)? selectableDayPredicate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final bool expandToFit;
  final M3EDatePickerMode? mode;
  final ValueChanged<M3EDatePickerMode>? onModeChanged;

  @override
  State<Md3eCalendarMonthPicker> createState() => _Md3eCalendarMonthPickerState();
}

class _Md3eCalendarMonthPickerState extends State<Md3eCalendarMonthPicker> {
  late PageController _pageController;
  late DateTime _currentMonth;
  late int _monthCount;

  @override
  void initState() {
    super.initState();
    _currentMonth = M3EDatePickerUtils.getMonth(
      widget.initialMonth.year,
      widget.initialMonth.month,
    );
    _monthCount =
        M3EDatePickerUtils.monthDelta(widget.firstDate, widget.lastDate) + 1;
    final int initialPage = M3EDatePickerUtils.monthDelta(
      widget.firstDate,
      _currentMonth,
    );
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    return M3EDatePickerUtils.addMonthsToMonthDate(widget.firstDate, page);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: M3EDatePickerConstants.monthScrollDuration,
      curve: Curves.ease,
    );
  }

  void _handlePreviousMonth() {
    final int page = _pageController.page?.round() ?? 0;
    if (page > 0) {
      _goToPage(page - 1);
    }
  }

  void _handleNextMonth() {
    final int page = _pageController.page?.round() ?? 0;
    if (page < _monthCount - 1) {
      _goToPage(page + 1);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final int page = _pageController.page?.round() ?? 0;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && page > 0) {
      _goToPage(page - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        page < _monthCount - 1) {
      _goToPage(page + 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKey,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _monthCount,
        onPageChanged: (int index) {
          final DateTime month = _monthForPage(index);
          setState(() => _currentMonth = month);
          widget.onMonthChanged(month);
        },
        itemBuilder: _buildMonthPage,
      ),
    );
  }

  Widget _buildMonthPage(BuildContext context, int index) {
    final DateTime month = _monthForPage(index);
    final int page = _pageController.hasClients
        ? (_pageController.page?.round() ?? 0)
        : M3EDatePickerUtils.monthDelta(widget.firstDate, _currentMonth);
    final bool canGoPrevious = page > 0;
    final bool canGoNext = page < _monthCount - 1;

    final Widget content = Column(
      mainAxisSize: widget.expandToFit ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        _MonthNavRow(
          month: month,
          canGoPrevious: canGoPrevious,
          canGoNext: canGoNext,
          onPrevious: _handlePreviousMonth,
          onNext: _handleNextMonth,
          mode: widget.mode,
          onModeChanged: widget.onModeChanged,
        ),
        if (widget.expandToFit)
          Expanded(
            child: Md3eCalendarDayPicker(
              displayedMonth: month,
              selectedDate: widget.selectedDate,
              currentDate: widget.currentDate,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onChanged: widget.onChanged,
              selectableDayPredicate: widget.selectableDayPredicate,
              rangeStart: widget.rangeStart,
              rangeEnd: widget.rangeEnd,
              fitHeight: true,
            ),
          )
        else
          Md3eCalendarDayPicker(
            displayedMonth: month,
            selectedDate: widget.selectedDate,
            currentDate: widget.currentDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onChanged: widget.onChanged,
            selectableDayPredicate: widget.selectableDayPredicate,
            rangeStart: widget.rangeStart,
            rangeEnd: widget.rangeEnd,
          ),
      ],
    );
    if (widget.expandToFit) {
      return content;
    }
    return UnconstrainedBox(
      constrainedAxis: Axis.horizontal,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: content,
    );
  }
}

class _MonthNavRow extends StatelessWidget {
  const _MonthNavRow({
    required this.month,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.mode,
    this.onModeChanged,
  });

  final DateTime month;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final M3EDatePickerMode? mode;
  final ValueChanged<M3EDatePickerMode>? onModeChanged;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EDatePickerTheme dateTheme = theme.datePickerTheme;
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final String label = localizations.formatMonthYear(month);

    return SizedBox(
      height: M3EDatePickerConstants.subHeaderHeight,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: mode != null && onModeChanged != null
                  ? M3ETappable(
                      onTap: () => onModeChanged!(M3EDatePickerMode.year),
                      semanticLabel: localizations.selectYearSemanticsLabel,
                      builder:
                          (BuildContext context, M3EInteractionState state) {
                            return _navLabelWithState(
                              theme: theme,
                              state: state,
                              child: Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.typeScale.titleSmall
                                          .copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    M3EIcons.arrow_drop_down,
                                    size: dateTheme.arrowIconSize,
                                  ),
                                ],
                              ),
                            );
                          },
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typeScale.titleSmall.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: M3EDatePickerConstants.monthNavButtonsWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                _MonthArrow(
                  enabled: canGoPrevious,
                  onTap: onPrevious,
                  tooltip: localizations.previousMonthTooltip,
                  icon: M3EIcons.chevron_left,
                  dateTheme: dateTheme,
                  theme: theme,
                ),
                _MonthArrow(
                  enabled: canGoNext,
                  onTap: onNext,
                  tooltip: localizations.nextMonthTooltip,
                  icon: M3EIcons.chevron_right,
                  dateTheme: dateTheme,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.enabled,
    required this.onTap,
    required this.tooltip,
    required this.icon,
    required this.dateTheme,
    required this.theme,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;
  final IconData icon;
  final M3EDatePickerTheme dateTheme;
  final M3EThemeData theme;

  @override
  Widget build(BuildContext context) {
    return M3ETappable(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      semanticLabel: tooltip,
      builder: (BuildContext context, M3EInteractionState state) {
        return _navLabelWithState(
          theme: theme,
          state: state,
          borderRadius: BorderRadius.circular(dateTheme.arrowIconSize),
          child: Padding(
            padding: dateTheme.arrowPadding,
            child: Icon(
              icon,
              size: dateTheme.arrowIconSize,
              color: enabled
                  ? null
                  : M3EColorUtils.withOpacity(
                      theme.colorScheme.onSurface,
                      0.38,
                    ),
            ),
          ),
        );
      },
    );
  }
}

Widget _navLabelWithState({
  required M3EThemeData theme,
  required M3EInteractionState state,
  required Widget child,
  BorderRadius? borderRadius,
}) {
  final double stateAlpha = state.opacity;
  final Color stateColor = theme.colorScheme.onSurface;
  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      color: stateAlpha > 0
          ? stateColor.withValues(alpha: stateAlpha)
          : null,
    ),
    child: child,
  );
}
