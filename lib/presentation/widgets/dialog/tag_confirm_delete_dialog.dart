import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';

class TagConfirmDeleteDialog extends StatelessWidget {
  const TagConfirmDeleteDialog({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return FluentDialogShell(
      title: '确认删除',
      content: Text('将删除 $count 个标签，并同时从所有漫画中移除这些标签。此操作不可撤销。'),
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
          child: const Text('删除'),
        ),
      ],
    );
  }
}
