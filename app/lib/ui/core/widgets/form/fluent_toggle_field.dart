import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';

/// Fluent 风格布尔字段：`FormLabel` + 可点输入条 + 文案 + 只读 [ToggleSwitch]。
///
/// 整条切换；开关仅作状态指示（不单独接 [ToggleSwitch.onChange]）。
class FluentToggleField extends StatelessWidget {
  const FluentToggleField({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
    required this.checkedLabel,
    required this.uncheckedLabel,
    this.enabled = true,
  });

  final String labelText;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String checkedLabel;
  final String uncheckedLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String displayText = value ? checkedLabel : uncheckedLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FormLabel(labelText),
        SizedBox(height: tokens.spacing.sm - 2),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onChanged(!value) : null,
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 28),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: tokens.text.bodyMd,
                            color: cs.hentai.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sm),
                      // 只读指示：命中区在外层 InkWell，避免与开关手势双触发。
                      IgnorePointer(
                        child: ToggleSwitch(checked: value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
