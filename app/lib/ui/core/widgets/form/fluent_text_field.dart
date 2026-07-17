import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

class FluentTextField extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool autofocus;

  /// When true, reduces vertical padding for single-line fields (dialog forms).
  final bool isDense;

  const FluentTextField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.hintText,
    this.labelText,
    this.errorText,
    this.autofocus = false,
    this.isDense = false,
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
    final tokens = context.tokens;
    final isTextarea = widget.maxLines > 1;
    final bool useDense = widget.isDense && !isTextarea;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;
    final Color borderColor = hasError
        ? cs.error
        : _isFocused
        ? cs.hentai.inputBorderActive
        : cs.hentai.inputBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          FormLabel(widget.labelText!),
          SizedBox(
            height: useDense ? tokens.spacing.xs : tokens.spacing.sm - 2,
          ),
        ],
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              vertical: useDense ? 0 : tokens.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: cs.hentai.inputBackground,
              borderRadius: BorderRadius.circular(tokens.radius.md),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: _isFocused && !hasError
                  ? [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: widget.maxLines > 1
                  ? TextInputAction.newline
                  : TextInputAction.done,
              maxLines: widget.maxLines,
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                color: cs.hentai.textPrimary,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: cs.hentai.textPlaceholder,
                  fontSize: tokens.text.bodyMd,
                ),
                contentPadding: isTextarea
                    ? EdgeInsets.symmetric(
                        horizontal: tokens.spacing.md,
                        vertical: useDense
                            ? tokens.spacing.sm
                            : tokens.spacing.sm + 2,
                      )
                    : EdgeInsets.symmetric(
                        horizontal: tokens.spacing.md,
                        vertical: useDense
                            ? tokens.spacing.xs
                            : tokens.spacing.sm,
                      ),
                border: InputBorder.none,
                isDense: true,
                filled: false,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: tokens.spacing.xs),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.error,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class FormLabel extends StatelessWidget {
  final String text;

  const FormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: tokens.text.labelXs,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.hentai.textTertiary,
      ),
    );
  }
}
