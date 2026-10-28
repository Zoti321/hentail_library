import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 通用 outlined 文本字段（单行或多行），封装 [M3ETextField]。
///
/// Tag 等可组合输入直接用 [Md3eOutlinedTextFieldShell]；勿再在此复刻 shell。
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
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.showClearButton = false,
    this.clearButtonSemanticsLabel,
    this.showPasswordToggle = false,
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
  final Widget? leading;
  final Widget? trailing;
  final bool obscureText;
  final bool showClearButton;
  final String? clearButtonSemanticsLabel;
  final bool showPasswordToggle;

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
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return M3ETextField(
      controller: _controller,
      focusNode: _focusNode,
      label: widget.label,
      variant: M3ETextFieldVariant.outlined,
      placeholder: widget.hintText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLines: widget.maxLines,
      leading: widget.leading,
      trailing: widget.trailing,
      showClearButton: widget.showClearButton,
      clearButtonSemanticsLabel:
          widget.clearButtonSemanticsLabel ?? l10n.commonClear,
      showPasswordToggle: widget.showPasswordToggle,
      autofocus: widget.autofocus,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
