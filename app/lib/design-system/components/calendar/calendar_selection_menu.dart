import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

/// A replacing list for docked pickers, or a three-column modal year grid.
class CalendarSelectionMenu extends StatefulWidget {
  const CalendarSelectionMenu({
    required this.months,
    required this.year,
    required this.firstDate,
    required this.lastDate,
    required this.selected,
    required this.columns,
    required this.rowHeight,
    required this.onSelected,
    super.key,
  });
  final bool months;
  final int year;
  final DateTime firstDate;
  final DateTime lastDate;
  final int selected;
  final int columns;
  final double rowHeight;
  final ValueChanged<int> onSelected;
  @override
  State<CalendarSelectionMenu> createState() => _CalendarSelectionMenuState();
}

class _CalendarSelectionMenuState extends State<CalendarSelectionMenu> {
  late final ScrollController _scroll;
  int get _first => widget.months ? 1 : widget.firstDate.year;
  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(
      initialScrollOffset:
          (((widget.selected - _first) ~/ widget.columns) - 2).clamp(0, 10000) *
          widget.rowHeight,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colors = Theme.of(context).colorScheme;
    final list = GridView.builder(
      controller: _scroll,
      padding: EdgeInsetsDirectional.only(end: widget.columns == 1 ? 16 : 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        mainAxisExtent: widget.rowHeight,
      ),
      itemCount: widget.months ? 12 : widget.lastDate.year - _first + 1,
      itemBuilder: (context, index) {
        final value = _first + index;
        final selected = value == widget.selected;
        final date = DateTime(widget.year, value);
        final enabled =
            !widget.months ||
            (!DateTime(
                  date.year,
                  date.month + 1,
                  0,
                ).isBefore(widget.firstDate) &&
                !date.isAfter(widget.lastDate));
        final label = widget.months
            ? DateFormat.MMMM(locale).format(date)
            : l10n.formatYear(DateTime(value));
        return Semantics(
          key: ValueKey('calendar-menu-item-$value'),
          selected: selected,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.columns == 1 ? 0 : 8,
              vertical: widget.columns == 1 ? 0 : 4,
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                alignment: widget.columns == 1
                    ? AlignmentDirectional.centerStart
                    : Alignment.center,
                foregroundColor: selected && widget.columns > 1
                    ? colors.onPrimary
                    : colors.onSurface,
                backgroundColor: selected
                    ? widget.columns == 1
                          ? colors.surfaceContainerHighest
                          : colors.primary
                    : null,
                shape: widget.columns == 1
                    ? const RoundedRectangleBorder()
                    : const StadiumBorder(),
              ),
              onPressed: enabled ? () => widget.onSelected(value) : null,
              child: widget.columns == 1
                  ? Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 24,
                                  semanticLabel: null,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(label)),
                      ],
                    )
                  : Text(label),
            ),
          ),
        );
      },
    );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: widget.columns == 1
          ? RawScrollbar(
              controller: _scroll,
              thumbVisibility: true,
              thickness: 6,
              crossAxisMargin: 2,
              thumbColor: colors.onSurfaceVariant.withValues(alpha: 0.5),
              radius: const Radius.circular(3),
              child: list,
            )
          : list,
    );
  }
}
