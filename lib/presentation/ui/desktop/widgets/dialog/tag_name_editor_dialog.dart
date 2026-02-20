import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/fluent_dialog_shell.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';

class TagNameEditorDialog extends ConsumerStatefulWidget {
  const TagNameEditorDialog({
    super.key,
    required this.title,
    required this.labelText,
    required this.hintText,
    required this.initialValue,
    required this.onSubmit,
    this.shouldCloseOnUnchanged = false,
  });

  final String title;
  final String labelText;
  final String hintText;
  final String initialValue;
  final Future<void> Function(String value) onSubmit;
  final bool shouldCloseOnUnchanged;

  @override
  ConsumerState<TagNameEditorDialog> createState() =>
      _TagNameEditorDialogState();
}

class _TagNameEditorDialogState extends ConsumerState<TagNameEditorDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    if (widget.shouldCloseOnUnchanged && value == widget.initialValue.trim()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(value);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FluentDialogShell(
      title: widget.title,
      content: FluentTextField(
        initialValue: _controller.text,
        labelText: widget.labelText,
        hintText: widget.hintText,
        autofocus: true,
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
