import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/md3e_suggestion_chip_surface.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 桌面端 FAB 草稿 chip：与普通 suggestion chip 同壳，仅光标 + 可输入文本。
const double kMd3eManagementDraftEntityChipWidth = 96;

class Md3eManagementDraftEntityChip extends StatefulWidget {
  const Md3eManagementDraftEntityChip({
    super.key,
    this.width = kMd3eManagementDraftEntityChipWidth,
    required this.onCommit,
    required this.onDismiss,
  });

  final double width;
  final ValueChanged<String> onCommit;
  final VoidCallback onDismiss;

  @override
  State<Md3eManagementDraftEntityChip> createState() =>
      _Md3eManagementDraftEntityChipState();
}

class _Md3eManagementDraftEntityChipState
    extends State<Md3eManagementDraftEntityChip> {
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
      child: Md3eSuggestionChipSurface(
        width: widget.width,
        staticChrome: true,
        editingFocusNode: _focusNode,
        onPressed: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
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
