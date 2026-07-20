import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

/// 从已保存路径列表中移除单条路径前的确认对话框。
class RemoveSavedPathConfirmDialog extends StatelessWidget {
  const RemoveSavedPathConfirmDialog({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return HentaiDialog(
      title: l10n.confirmRemovePathTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.confirmRemovePathContent,
            style: TextStyle(fontSize: 14, color: cs.hentai.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            path,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.hentai.textPrimary,
            ),
          ),
        ],
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
          child: Text(l10n.commonRemove),
        ),
      ],
    );
  }
}
