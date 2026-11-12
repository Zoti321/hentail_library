import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/design-system/components/inputs/compact_input_chip.dart';
import 'package:hentai_library/design-system/components/inputs/input_chip_field_layout.dart';
import 'package:hentai_library/design-system/components/inputs/outlined_text_field_shell.dart';

/// Default min width for tag input previews (lab text fields).
const double kTagInputFieldMinWidth = 280;

/// Default max width for tag input previews.
const double kTagInputFieldMaxWidth = 560;

/// Tag input: [OutlinedTextFieldShell] + input chips in a [Wrap].
class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.label,
    required this.tags,
    this.minWidth = kTagInputFieldMinWidth,
    this.maxWidth = kTagInputFieldMaxWidth,
    this.onTagRemoved,
    this.onTagCommitted,
  });

  final String label;
  final List<String> tags;
  final double minWidth;
  final double maxWidth;
  final ValueChanged<String>? onTagRemoved;
  final ValueChanged<String>? onTagCommitted;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitTag() {
    final String tag = inputChipCommitLabel(_controller.text);
    if (tag.isEmpty) {
      return;
    }
    widget.onTagCommitted?.call(tag);
    _controller.clear();
  }

  void _focusInput() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minWidth,
        maxWidth: widget.maxWidth,
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          return OutlinedTextFieldShell(
            label: widget.label,
            focusNode: _focusNode,
            iconSlotAlignment: M3ETextFieldSlotAlignment.firstLine,
            chipFirstLineLayout: true,
            isPopulated: widget.tags.isNotEmpty || _controller.text.isNotEmpty,
            selectionController: _controller,
            editableTextKey: _editableKey,
            inputBuilder:
                (
                  BuildContext context,
                  M3ETextFieldColors colors,
                  M3ETextFieldTheme fieldTheme,
                  TextStyle inputStyle,
                ) {
                  final M3EChipTheme chipTheme = M3ETheme.of(context).chipTheme;
                  final bool hasChips = widget.tags.isNotEmpty;
                  final ({
                    double rowLineHeight,
                    double textTopInset,
                    double inlineWidth,
                  })
                  metrics = resolveInputChipInlineMetrics(
                    chipTheme: chipTheme,
                    inputStyle: inputStyle,
                    text: _controller.text,
                    hasChips: hasChips,
                  );

                  return InputChipFieldContent(
                    fieldTheme: fieldTheme,
                    inputStyle: inputStyle,
                    hasChips: hasChips,
                    onTap: _focusInput,
                    chips: <Widget>[
                      for (final String tag in widget.tags)
                        CompactInputChip(
                          label: tag,
                          onPressed: _focusInput,
                          onDeleted: widget.onTagRemoved == null
                              ? null
                              : () => widget.onTagRemoved!(tag),
                        ),
                    ],
                    inlineField: SizedBox(
                      width: metrics.inlineWidth,
                      height: metrics.rowLineHeight,
                      child: Padding(
                        padding: EdgeInsets.only(top: metrics.textTopInset),
                        child: CallbackShortcuts(
                          bindings: M3EFocus.editableInputShortcuts(_focusNode),
                          child: EditableText(
                            key: _editableKey,
                            controller: _controller,
                            focusNode: _focusNode,
                            style: inputStyle,
                            cursorColor: colors.caret,
                            backgroundCursorColor: M3ETheme.of(context)
                                .colorScheme
                                .outlineVariant,
                            selectionColor: M3ETheme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: fieldTheme.selectionOpacity),
                            textCapitalization: TextCapitalization.none,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _commitTag(),
                            maxLines: 1,
                            scrollPadding: EdgeInsets.zero,
                            rendererIgnoresPointer: true,
                            selectionControls: m3eTextFieldSelectionControls(
                              defaultTargetPlatform,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
          );
        },
      ),
    );
  }
}
