import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field_shell.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 通用 outlined 文本字段（单行或多行）。
class Md3eOutlinedTextField extends StatefulWidget {
  const Md3eOutlinedTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.labelTrailing,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final String? hintText;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final Widget? labelTrailing;

  @override
  State<Md3eOutlinedTextField> createState() => _Md3eOutlinedTextFieldState();
}

class _Md3eOutlinedTextFieldState extends State<Md3eOutlinedTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller = widget.controller ??
        TextEditingController(text: widget.initialValue ?? '');
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant Md3eOutlinedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ownsController &&
        widget.initialValue != null &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final Widget field = Md3eOutlinedTextFieldShell(
      label: widget.label,
      focusNode: _focusNode,
      enabled: widget.enabled,
      isPopulated: _controller.text.isNotEmpty,
      trailing: widget.trailing,
      labelTrailing: widget.labelTrailing,
      inputBuilder:
          (
            BuildContext context,
            M3ETextFieldColors colors,
            M3ETextFieldTheme fieldTheme,
            TextStyle inputStyle,
          ) {
            return CallbackShortcuts(
              bindings: M3EFocus.editableInputShortcuts(_focusNode),
              child: EditableText(
                controller: _controller,
                focusNode: _focusNode,
                style: inputStyle,
                cursorColor: colors.caret,
                backgroundCursorColor: theme.colorScheme.outlineVariant,
                selectionColor: theme.colorScheme.primary
                    .withValues(alpha: fieldTheme.selectionOpacity),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction ??
                    (widget.maxLines > 1
                        ? TextInputAction.newline
                        : TextInputAction.done),
                onSubmitted: widget.onSubmitted,
                maxLines: widget.maxLines,
                scrollPadding: EdgeInsets.zero,
                selectionControls: m3eTextFieldSelectionControls(
                  defaultTargetPlatform,
                ),
              ),
            );
          },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        field,
        if (widget.errorText != null) ...<Widget>[
          SizedBox(height: spacing.xs),
          Text(
            widget.errorText!,
            style: theme.typeScale.bodySmall.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
