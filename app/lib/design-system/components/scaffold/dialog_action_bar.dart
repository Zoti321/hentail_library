import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/theme/lab_text.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 对话框动作行：取消 + 确认，支持危险态、禁用态与保存中行内进度。
///
/// 文案由调用方注入（本组件不取 l10n）。
class DialogActionBar extends StatelessWidget {
  const DialogActionBar({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
    this.confirmEnabled = true,
    this.saving = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final bool confirmEnabled;

  /// true 时确认按钮显示行内进度，且两键均禁用。
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle labelStyle = labButtonLabelStyle(theme, M3EButtonSize.sm);
    final bool confirmActive = confirmEnabled && !saving;
    final M3EButtonDecoration filledDecoration = destructive
        ? M3EButtonDecoration.styleFrom(
            textStyle: labelStyle,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
            disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          )
        : M3EButtonDecoration(textStyle: labelStyle);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        M3EButton(
          onPressed: saving ? null : onCancel,
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: labelStyle),
          label: Text(cancelLabel),
        ),
        const SizedBox(width: 8),
        M3EButton(
          onPressed: confirmActive ? onConfirm : null,
          style: M3EButtonStyle.filled,
          decoration: filledDecoration,
          label: saving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: M3EProgressIndicator.circular(
                        size: 14,
                        strokeWidth: 2,
                        color: destructive ? scheme.onError : scheme.onPrimary,
                        showTrack: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(confirmLabel),
                  ],
                )
              : Text(confirmLabel),
        ),
      ],
    );
  }
}
