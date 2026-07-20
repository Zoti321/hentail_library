import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

/// 清空全部阅读历史的确认对话框（与标签/系列删除确认对话框同一套 Fluent 壳层）。
class ClearReadingHistoryConfirmDialog extends StatelessWidget {
  const ClearReadingHistoryConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HentaiDialog(
      title: l10n.confirmClearHistoryTitle,
      content: Text(l10n.confirmClearHistoryContent),
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
          child: Text(l10n.commonClear),
        ),
      ],
    );
  }
}
