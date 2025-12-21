import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';

class FluentTextField extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final int maxLines;
  final String? hintText;
  final String? labelText;

  const FluentTextField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    this.hintText,
    this.labelText,
  });

  @override
  State<FluentTextField> createState() => FluentTextFieldState();
}

class FluentTextFieldState extends State<FluentTextField> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTextarea = widget.maxLines > 1;

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          FormLabel(widget.labelText!),
          const SizedBox(height: 6),
        ],
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const .symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused
                    ? Theme.of(context).colorScheme.inputBorderActive
                    : Theme.of(context).colorScheme.inputBorder,
                width: 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              maxLines: widget.maxLines,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.textPrimary,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.textPlaceholder,
                  fontSize: 14,
                ),
                contentPadding: isTextarea
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: InputBorder.none,
                isDense: true,
                filled: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FormLabel extends StatelessWidget {
  final String text;

  const FormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.textTertiary,
      ),
    );
  }
}
