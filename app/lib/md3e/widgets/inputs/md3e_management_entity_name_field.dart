import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field_shell.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页新建实体：单行 outlined 输入（Dialog 与桌面内联共用）。
class Md3eManagementEntityNameField extends StatefulWidget {
  const Md3eManagementEntityNameField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<Md3eManagementEntityNameField> createState() =>
      _Md3eManagementEntityNameFieldState();
}

class _Md3eManagementEntityNameFieldState
    extends State<Md3eManagementEntityNameField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
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
    setState(() {});
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    widget.onSubmitted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Md3eOutlinedTextFieldShell(
      label: widget.label,
      focusNode: _focusNode,
      isPopulated: _controller.text.isNotEmpty,
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
                backgroundCursorColor:
                    M3ETheme.of(context).colorScheme.outlineVariant,
                selectionColor: M3ETheme.of(context).colorScheme.primary
                    .withValues(alpha: fieldTheme.selectionOpacity),
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                maxLines: 1,
                scrollPadding: EdgeInsets.zero,
                selectionControls: m3eTextFieldSelectionControls(
                  defaultTargetPlatform,
                ),
              ),
            );
          },
    );
  }
}
