import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/embeddable_calendar_date_picker.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画元数据发布日期默认可选范围（与 Lab 预览一致）。
final DateTime kPublishedDatePickerFirstDate = DateTime(1970);
final DateTime kPublishedDatePickerLastDate = DateTime(2030, 12, 31);

/// 贴在表单字段下方的 docked 日历（非 Dialog）；仅一层 M3E 容器背景。
class DockedCalendarDatePicker extends StatelessWidget {
  const DockedCalendarDatePicker({
    super.key,
    required this.onDateChanged,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.initialCalendarMode = M3EDatePickerMode.year,
  });

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final M3EDatePickerMode initialCalendarMode;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Padding(
      padding: EdgeInsets.only(top: spacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: EmbeddableCalendarDatePicker(
          initialDate: initialDate,
          firstDate: firstDate ?? kPublishedDatePickerFirstDate,
          lastDate: lastDate ?? kPublishedDatePickerLastDate,
          initialCalendarMode: initialCalendarMode,
          expandToFit: false,
          onDateChanged: onDateChanged,
        ),
      ),
    );
  }
}
