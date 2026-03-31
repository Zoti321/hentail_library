import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hentai_library/config/theme.dart';

class DatePicker extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChange;

  const DatePicker({super.key, required this.value, required this.onChange});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  bool _isOpen = false;
  DateTime _currentMonth = DateTime.now();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final OverlayPortalController _portalController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isOpen) {
        _toggleOpen();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  void _toggleOpen() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        if (widget.value.isNotEmpty) {
          final parts = widget.value.split('-').map(int.parse).toList();
          if (parts.length == 3) {
            _currentMonth = DateTime(parts[0], parts[1], 1);
          }
        }
        _portalController.show();
      } else {
        _portalController.hide();
      }
    });
  }

  void _selectDate(int day) {
    final newDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    widget.onChange(_formatDate(newDate));
    _toggleOpen();
  }

  void _handlePrevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _handleNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _handleClear() {
    widget.onChange('');
  }

  Widget _buildDayButton(int day) {
    final dateStr = _formatDate(
      DateTime(_currentMonth.year, _currentMonth.month, day),
    );
    final isSelected = widget.value == dateStr;
    final isToday = _formatDate(DateTime.now()) == dateStr;

    Color? bgColor;
    Color textColor = Theme.of(context).colorScheme.textSecondary;
    FontWeight? fontWeight;

    if (isSelected) {
      bgColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
      fontWeight = FontWeight.w500;
    } else if (isToday) {
      textColor = Theme.of(context).colorScheme.primary;
      fontWeight = FontWeight.bold;
    }

    return InkWell(
      onTap: () => _selectDate(day),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = widget.value.isEmpty ? '选择日期' : widget.value;
    final borderColor = _isOpen
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.borderSubtle;

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (context) => Material(
          color: Colors.transparent,
          child: CompositedTransformFollower(
            link: _layerLink,
            followerAnchor: Alignment.topLeft,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(0, 8),
            child: GestureDetector(
              onTap: () {},
                  child: Align(
                alignment: .topLeft,
                child: TapRegion(
                  onTapOutside: (_) => _toggleOpen(),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                          color: Theme.of(context).colorScheme.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              _buildNavButton(
                                LucideIcons.chevronLeft,
                                _handlePrevMonth,
                              ),
                              Text(
                                '${_currentMonth.year}年${_currentMonth.month}月',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.textPrimary,
                                ),
                              ),
                              _buildNavButton(
                                LucideIcons.chevronRight,
                                _handleNextMonth,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: .spaceAround,
                            children: ['日', '一', '二', '三', '四', '五', '六']
                                .map(
                                  (d) => SizedBox(
                                    width: 28,
                                    height: 20,
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .textPlaceholder,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 4),
                          _buildCalendarGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggleOpen,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: widget.value.isEmpty
                          ? Theme.of(context).colorScheme.textPlaceholder
                          : Theme.of(context).colorScheme.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.value.isEmpty
                            ? Theme.of(context).colorScheme.textPlaceholder
                            : Theme.of(context).colorScheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (widget.value.isNotEmpty)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _handleClear,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .inputBackgroundDisabled,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color:
                                  Theme.of(context).colorScheme.textPlaceholder,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final totalDays = _daysInMonth(_currentMonth);
    final startOffset = _firstDayOfMonth(_currentMonth);
    final List<Widget> weeks = [];

    List<Widget> currentWeek = [];
    for (int i = 0; i < startOffset; i++) {
      currentWeek.add(const SizedBox(width: 28, height: 28));
    }

    for (int day = 1; day <= totalDays; day++) {
      currentWeek.add(_buildDayButton(day));
      if (currentWeek.length == 7) {
        weeks.add(
          Row(
            mainAxisAlignment: .spaceAround,
            children: List.from(currentWeek),
          ),
        );
        currentWeek.clear();
      }
    }

    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(const SizedBox(width: 28, height: 28));
      }

      weeks.add(
        Row(mainAxisAlignment: .spaceAround, children: List.from(currentWeek)),
      );
    }

    return Column(children: weeks);
  }
}
