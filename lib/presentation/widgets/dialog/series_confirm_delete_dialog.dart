import 'package:flutter/material.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';

class SeriesConfirmDeleteDialog extends StatelessWidget {
  const SeriesConfirmDeleteDialog({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final count = series.items.length;
    final extra = count > 0
        ? '该系列包含 $count 本漫画，将移除系列归属，漫画仍保留在库中。'
        : '删除后无法恢复。';

    return FluentDialogShell(
      title: '确认删除',
      content: Text('确定删除系列「${series.name}」？$extra'),
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
