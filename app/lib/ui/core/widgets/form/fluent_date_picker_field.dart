import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String formatFluentDatePickerLabel(DateTime date) {
  return DateFormat('yyyy年MM月dd日').format(date.toLocal());
}

/// 只读日期字段：点击打开 [showDatePicker]，支持清空。
class FluentDatePickerField extends StatelessWidget {
  const FluentDatePickerField({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.hintText = '选择发布日期',
    this.enabled = true,
  });

  final String labelText;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hintText;
  final bool enabled;

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) {
      return;
    }
    final DateTime now = DateTime.now();
    final AppThemeTokens tokens = context.tokens;
    final ThemeData baseTheme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDate: value ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: '选择发布日期',
      cancelText: '取消',
      confirmText: '确定',
      fieldLabelText: '日期',
      fieldHintText: '年/月/日',
      errorFormatText: '日期格式无效',
      errorInvalidText: '日期超出可选范围',
      builder: (BuildContext context, Widget? child) {
        // Rely on MaterialApp Global* delegates for MaterialLocalizations.
        // Do not wrap a fresh Localizations here — its async load races the
        // first DatePickerDialog frame and throws "No MaterialLocalizations".
        return Theme(
          data: baseTheme.copyWith(
            datePickerTheme: baseTheme.datePickerTheme.copyWith(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radius.xs),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      onChanged(DateTime.utc(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? displayText = value == null
        ? null
        : formatFluentDatePickerLabel(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FormLabel(labelText),
        SizedBox(height: tokens.spacing.sm - 2),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _pickDate(context) : null,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.hentai.inputBackground,
                borderRadius: BorderRadius.circular(tokens.radius.md),
                border: Border.all(color: cs.hentai.inputBorder, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.md,
                  vertical: tokens.spacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    SizedBox(width: tokens.spacing.sm),
                    Expanded(
                      child: Text(
                        displayText ?? hintText,
                        style: TextStyle(
                          fontSize: tokens.text.bodyMd,
                          color: displayText == null
                              ? cs.hentai.textPlaceholder
                              : cs.hentai.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (value != null && enabled)
                      IconButton(
                        tooltip: '清空日期',
                        onPressed: () => onChanged(null),
                        icon: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
