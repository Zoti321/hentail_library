import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/tag_chip.dart';

/// 字符串标签编辑（作者名、通用标签等）。
class TagEditorField extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const TagEditorField({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<TagEditorField> createState() => TagEditorFieldState();
}

class TagEditorFieldState extends State<TagEditorField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onAdd(_controller.text.trim());
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  void _handleContainerTap() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: Theme.of(context).colorScheme.textTertiary,
            ),
            const SizedBox(width: 8),
            FormLabel(widget.label),
          ],
        ),
        GestureDetector(
          onTap: _handleContainerTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.borderSubtle,
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow,
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: widget.items.isEmpty ? "添加标签..." : null,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.textPlaceholder,
                ),
              ),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.textPrimary,
                height: 1.4,
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
          ),
        ),
        if (widget.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.items
                  .map(
                    (name) => CategoryTagChip(
                      label: name,
                      onRemove: () => widget.onRemove(name),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
