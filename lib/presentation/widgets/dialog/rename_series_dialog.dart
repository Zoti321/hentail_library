import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';
import 'package:hentai_library/presentation/widgets/form/fluent_text_field.dart';

class RenameSeriesDialog extends ConsumerStatefulWidget {
  const RenameSeriesDialog({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<RenameSeriesDialog> createState() => _RenameSeriesDialogState();
}

class _RenameSeriesDialogState extends ConsumerState<RenameSeriesDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.series.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty || newName == widget.series.name) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(seriesActionsProvider).rename(widget.series.name, newName);
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessSnackBar(context, '已重命名');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FluentDialogShell(
      title: '重命名系列',
      content: FluentTextField(
        initialValue: _controller.text,
        labelText: '新名称',
        hintText: '输入新的系列名称…',
        onChanged: (value) => _controller.text = value,
        onSubmitted: (_) async {
          if (_saving) return;
          await _handleSave();
        },
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
