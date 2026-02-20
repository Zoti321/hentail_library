import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/fluent_dialog_shell.dart';

/// 批量移除已保存路径前的确认对话框。
class RemoveSavedPathsBatchConfirmDialog extends StatelessWidget {
  const RemoveSavedPathsBatchConfirmDialog({super.key, required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    const int previewMax = 6;
    final List<String> preview = paths.length <= previewMax
        ? paths
        : paths.sublist(0, previewMax);
    final bool hasMore = paths.length > previewMax;
    return FluentDialogShell(
      title: '确认移除',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '将从库中移除已选中的 ${paths.length} 条路径。此操作不可撤销。',
            style: TextStyle(fontSize: 14, color: cs.textSecondary),
          ),
          const SizedBox(height: 10),
          ...preview.map(
            (String p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                p,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.textPrimary,
                ),
              ),
            ),
          ),
          if (hasMore)
            Text(
              '… 共 ${paths.length} 项',
              style: TextStyle(fontSize: 12, color: cs.textTertiary),
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
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('移除'),
        ),
      ],
    );
  }
}
