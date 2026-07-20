import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 只读日期字段：点击打开 [showDatePicker]，支持清空。
class FluentDatePickerField extends StatelessWidget {
  const FluentDatePickerField({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  final String labelText;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? hintText;
  final bool enabled;

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) {
      return;
    }
    final l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final DateTime now = DateTime.now();
    final AppThemeTokens tokens = context.tokens;
    final ThemeData baseTheme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: locale,
      initialDate: value ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: l10n.formDatePickerHelp,
      cancelText: l10n.commonCancel,
      confirmText: l10n.commonOk,
      fieldLabelText: l10n.formDateFieldLabel,
      fieldHintText: l10n.formDateFieldHint,
      errorFormatText: l10n.formDateInvalidFormat,
      errorInvalidText: l10n.formDateOutOfRange,
      builder: (BuildContext context, Widget? child) {
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
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String effectiveHint = hintText ?? l10n.formDatePickerHint;
    final String? displayText = value == null
        ? null
        : l10n.formatFluentDatePickerLabel(
            value!,
            Localizations.localeOf(context),
          );

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
                        displayText ?? effectiveHint,
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
                        tooltip: l10n.formDateClearTooltip,
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
