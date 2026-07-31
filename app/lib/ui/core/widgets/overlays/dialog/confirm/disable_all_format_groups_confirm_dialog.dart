import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

/// 保存「支持的资源格式」为全关前的强确认对话框。
class DisableAllFormatGroupsConfirmDialog extends StatelessWidget {
  const DisableAllFormatGroupsConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return HentaiDialog(
      title: l10n.settingsDisableAllFormatsConfirmTitle,
      content: Text(
        l10n.settingsDisableAllFormatsConfirmContent,
        style: TextStyle(fontSize: 14, color: cs.hentai.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
