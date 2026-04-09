import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';

/// 清空全部阅读历史的确认对话框（与标签/系列删除确认对话框同一套 Fluent 壳层）。
class ClearReadingHistoryConfirmDialog extends StatelessWidget {
  const ClearReadingHistoryConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentDialogShell(
      title: '确认清空',
      content: const Text('将清空全部阅读历史记录。此操作不可撤销。'),
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
          child: const Text('清空'),
        ),
      ],
    );
  }
}
