import 'dart:math' as math;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// 与 [Md3eCalendarYearPicker] 网格行高一致（略高于 M3E 默认 52，便于胶囊选中态留白）。
const double kMd3eCalendarYearPickerRowHeight = 56;

const double _kYearChipHeight = 40;
const double _kYearChipHorizontalPadding = 12;
final BorderRadius _kYearChipRadius = BorderRadius.circular(20);

/// Lab 年份视图高度（对齐 [M3EDatePickerUtils.calendarYearViewHeight]，使用 [kMd3eCalendarYearPickerRowHeight]）。
double md3eCalendarYearViewHeight(
  DateTime firstDate,
  DateTime lastDate, {
  bool includeSubHeader = true,
}) {
  final int yearCount = lastDate.year - firstDate.year + 1;
  final int rows = M3EDatePickerUtils.yearPickerRowCount(yearCount);
  final double natural = M3EDatePickerConstants.yearPickerPadding * 2 +
      rows * kMd3eCalendarYearPickerRowHeight +
      (rows - 1) * M3EDatePickerConstants.yearPickerRowSpacing;
  var height = math.min(
    natural,
    M3EDatePickerConstants.maxDayPickerHeight,
  );
  if (includeSubHeader) {
    height += M3EDatePickerConstants.subHeaderHeight;
  }
  return height;
}

/// Lab 年份网格：在 M3E 默认圆形选中态基础上改为胶囊形，避免 CJK `formatYear`（如「2022年」）贴边。
///
/// 行为对齐 `material_3_expressive` `M3EYearPicker`；上游为固定直径圆形容器。
class Md3eCalendarYearPicker extends StatefulWidget {
  const Md3eCalendarYearPicker({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.selectableDayPredicate,
    this.displayedMonth,
    super.key,
  });

  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool Function(DateTime day)? selectableDayPredicate;
  final DateTime? displayedMonth;

  @override
  State<Md3eCalendarYearPicker> createState() => _Md3eCalendarYearPickerState();
}

class _Md3eCalendarYearPickerState extends State<Md3eCalendarYearPicker> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final int selectedYear =
        widget.selectedDate?.year ?? widget.firstDate.year;
    _controller = ScrollController(
      initialScrollOffset: _initialOffset(
        selectedYear,
        widget.firstDate.year,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EDatePickerTheme dateTheme = theme.datePickerTheme;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final int firstYear = widget.firstDate.year;
    final int lastYear = widget.lastDate.year;
    final int yearCount = lastYear - firstYear + 1;
    final int selectedYear = widget.selectedDate?.year ?? firstYear;

    return Column(
      children: <Widget>[
        const M3EDivider(),
        Expanded(
          child: GridView.builder(
            controller: _controller,
            padding: const EdgeInsets.symmetric(
              horizontal: M3EDatePickerConstants.yearPickerPadding,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: M3EDatePickerConstants.yearPickerColumnCount,
              mainAxisExtent: kMd3eCalendarYearPickerRowHeight,
              mainAxisSpacing: M3EDatePickerConstants.yearPickerRowSpacing,
              crossAxisSpacing: M3EDatePickerConstants.yearPickerRowSpacing,
            ),
            itemCount: yearCount,
            itemBuilder: (BuildContext context, int index) {
              return _buildYearCell(
                theme: theme,
                dateTheme: dateTheme,
                localizations: localizations,
                year: firstYear + index,
                selectedYear: selectedYear,
              );
            },
          ),
        ),
        const M3EDivider(),
      ],
    );
  }

  Widget _buildYearCell({
    required M3EThemeData theme,
    required M3EDatePickerTheme dateTheme,
    required MaterialLocalizations localizations,
    required int year,
    required int selectedYear,
  }) {
    final DateTime normalized = M3EDatePickerUtils.clampDate(
      M3EDatePickerUtils.normalizeSelectedDay(
        widget.selectedDate ?? DateTime(year),
        DateTime(year, widget.selectedDate?.month ?? 1),
      ),
      widget.firstDate,
      widget.lastDate,
    );
    final DateTime candidate = DateTime(year, normalized.month, normalized.day);
    final bool enabled = M3EDatePickerUtils.isSelectable(
      candidate,
      widget.firstDate,
      widget.lastDate,
      predicate: widget.selectableDayPredicate,
    );
    final bool selected = year == selectedYear;
    final Color foreground = dateTheme.yearForegroundColor(
      theme.colorScheme,
      selected: selected,
      enabled: enabled,
    );
    return SizedBox(
      height: kMd3eCalendarYearPickerRowHeight,
      width: double.infinity,
      child: Center(
        child: M3ETappable(
          enabled: enabled,
          onTap: enabled ? () => widget.onChanged(candidate) : null,
          semanticLabel: localizations.formatYear(DateTime(year)),
          builder: (BuildContext context, M3EInteractionState state) {
            final M3EColorScheme scheme = theme.colorScheme;
            final Color stateBase =
                selected ? scheme.onPrimary : scheme.onSurface;
            final double stateAlpha = enabled ? state.opacity : 0;
            return SizedBox(
              height: _kYearChipHeight,
              width: double.infinity,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: _kYearChipHorizontalPadding,
                ),
                decoration: BoxDecoration(
                  borderRadius: _kYearChipRadius,
                  color: selected
                      ? dateTheme.selectedDayBackgroundColor(scheme)
                      : null,
                ),
                foregroundDecoration: stateAlpha > 0
                    ? BoxDecoration(
                        borderRadius: _kYearChipRadius,
                        color: stateBase.withValues(alpha: stateAlpha),
                      )
                    : null,
                child: Text(
                  localizations.formatYear(DateTime(year)),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: (selected
                          ? dateTheme.selectedYearStyle
                          : dateTheme.yearStyle)(
                        theme.typeScale,
                        scheme,
                      ).copyWith(color: foreground),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static double _initialOffset(int selectedYear, int firstYear) {
    const double rowHeight =
        kMd3eCalendarYearPickerRowHeight +
        M3EDatePickerConstants.yearPickerRowSpacing;
    const int columns = M3EDatePickerConstants.yearPickerColumnCount;
    final int row = ((selectedYear - firstYear) / columns).floor();
    return row * rowHeight;
  }
}
