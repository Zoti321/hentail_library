import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';
import 'package:hentai_library/presentation/widgets/form/fluent_text_field.dart';

class AddSeriesDialog extends ConsumerStatefulWidget {
  const AddSeriesDialog({super.key});

  @override
  ConsumerState<AddSeriesDialog> createState() => _AddSeriesDialogState();
}

class _AddSeriesDialogState extends ConsumerState<AddSeriesDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(seriesActionsProvider).create(name);
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessSnackBar(context, '已添加系列');
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
      title: '添加系列',
      content: FluentTextField(
        initialValue: _nameController.text,
        labelText: '名称',
        hintText: '输入系列名称…',
        onChanged: (value) => _nameController.text = value,
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
