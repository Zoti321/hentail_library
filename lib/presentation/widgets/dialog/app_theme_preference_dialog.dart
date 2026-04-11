import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/app_setting.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 选择应用主题（跟随系统 / 浅色 / 深色）。
class AppThemePreferenceDialog extends StatelessWidget {
  const AppThemePreferenceDialog({super.key, required this.current});

  final AppThemePreference current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return FluentDialogShell(
      title: '应用主题',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: AppThemePreference.values.map((AppThemePreference p) {
          final bool isSelected = p == current;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(p),
                borderRadius: BorderRadius.circular(tokens.radius.md),
                hoverColor: cs.primary.withAlpha(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacing.sm,
                    vertical: tokens.spacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? LucideIcons.circleCheckBig
                            : LucideIcons.circle,
                        size: 18,
                        color: isSelected ? cs.primary : cs.textTertiary,
                      ),
                      SizedBox(width: tokens.spacing.sm),
                      Expanded(
                        child: Text(
                          p.labelZh,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
