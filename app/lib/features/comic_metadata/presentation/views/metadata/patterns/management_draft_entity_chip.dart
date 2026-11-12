import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 桌面端新建草稿 chip（生产与 Lab 共用）：与 suggestion chip 同壳，仅光标 + 可输入文本。
const double kManagementDraftEntityChipWidth = 96;

class ManagementDraftEntityChip extends StatefulWidget {
  const ManagementDraftEntityChip({
    super.key,
    this.width = kManagementDraftEntityChipWidth,
    required this.onCommit,
    required this.onDismiss,
  });

  final double width;
  final ValueChanged<String> onCommit;
  final VoidCallback onDismiss;

  @override
  State<ManagementDraftEntityChip> createState() =>
      _ManagementDraftEntityChipState();
}

class _ManagementDraftEntityChipState extends State<ManagementDraftEntityChip> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePressed() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && !_closing) {
      _closing = true;
      widget.onDismiss();
    }
  }

  void _submit() {
    if (_closing) {
      return;
    }
    _closing = true;
    final String value = _controller.text.trim();
    if (value.isNotEmpty) {
      widget.onCommit(value);
      return;
    }
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle inputStyle = theme.typeScale.labelLarge.copyWith(
      color: theme.chipTheme.labelColor(
        scheme,
        enabled: true,
        selected: false,
        type: M3EChipType.suggestion,
      ),
    );

    return TextFieldTapRegion(
      onTapOutside: M3EFocus.tapOutsideHandler(_focusNode),
      child: SuggestionChipSurface(
        width: widget.width,
        staticChrome: true,
        editingFocusNode: _focusNode,
        onPressed: _handlePressed,
        child: CallbackShortcuts(
          bindings: M3EFocus.editableInputShortcuts(_focusNode),
          child: EditableText(
            controller: _controller,
            focusNode: _focusNode,
            style: inputStyle,
            cursorColor: scheme.primary,
            backgroundCursorColor: scheme.outlineVariant,
            selectionColor: scheme.primary.withValues(alpha: 0.3),
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            maxLines: 1,
            scrollPadding: EdgeInsets.zero,
            selectionControls: m3eTextFieldSelectionControls(
              defaultTargetPlatform,
            ),
          ),
        ),
      ),
    );
  }
}
