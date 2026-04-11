import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';

/// 从已保存路径列表中移除单条路径前的确认对话框。
class RemoveSavedPathConfirmDialog extends StatelessWidget {
  const RemoveSavedPathConfirmDialog({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return FluentDialogShell(
      title: '确认移除',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '将从库中移除该路径。此操作不可撤销。',
            style: TextStyle(fontSize: 14, color: cs.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            path,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.textPrimary,
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
