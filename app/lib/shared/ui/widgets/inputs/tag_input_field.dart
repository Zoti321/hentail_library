import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_input_chip_field_layout.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field_shell.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Default min width for tag input previews (lab text fields).
const double kMd3eTagInputFieldMinWidth = 280;

/// Default max width for tag input previews.
const double kMd3eTagInputFieldMaxWidth = 560;

/// Tag input: [Md3eOutlinedTextFieldShell] + input chips in a [Wrap].
class Md3eTagInputField extends StatefulWidget {
  const Md3eTagInputField({
    super.key,
    required this.label,
    required this.tags,
    this.minWidth = kMd3eTagInputFieldMinWidth,
    this.maxWidth = kMd3eTagInputFieldMaxWidth,
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
  State<Md3eTagInputField> createState() => _Md3eTagInputFieldState();
}

class _Md3eTagInputFieldState extends State<Md3eTagInputField> {
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
    final String tag = md3eInputChipCommitLabel(_controller.text);
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
          return Md3eOutlinedTextFieldShell(
            label: widget.label,
            focusNode: _focusNode,
            iconSlotAlignment: M3ETextFieldSlotAlignment.firstLine,
            chipFirstLineLayout: true,
            isPopulated:
                widget.tags.isNotEmpty || _controller.text.isNotEmpty,
            selectionController: _controller,
            editableTextKey: _editableKey,
            inputBuilder:
                (
                  BuildContext context,
                  M3ETextFieldColors colors,
                  M3ETextFieldTheme fieldTheme,
                  TextStyle inputStyle,
                ) {
                  final M3EChipTheme chipTheme =
                      M3ETheme.of(context).chipTheme;
                  final double inlineWidth = md3eInputChipInlineWidth(
                    style: inputStyle,
                    text: _controller.text,
                  );
                  final bool hasChips = widget.tags.isNotEmpty;
                  final double rowLineHeight = md3eInputChipRowLineHeight(
                    chipTheme: chipTheme,
                    inputStyle: inputStyle,
                    hasChips: hasChips,
                  );
                  final double textTopInset = hasChips
                      ? md3eInputChipInlineTopInset(
                          rowLineHeight: rowLineHeight,
                          inputStyle: inputStyle,
                        )
                      : 0;

                  return Md3eInputChipFieldContent(
                    fieldTheme: fieldTheme,
                    inputStyle: inputStyle,
                    hasChips: hasChips,
                    onTap: _focusInput,
                    chips: <Widget>[
                      for (final String tag in widget.tags)
                        md3eCompactInputChip(
                          context: context,
                          label: tag,
                          onPressed: _focusInput,
                          onDeleted: widget.onTagRemoved == null
                              ? null
                              : () => widget.onTagRemoved!(tag),
                        ),
                    ],
                    inlineField: SizedBox(
                      width: inlineWidth,
                      height: rowLineHeight,
                      child: Padding(
                        padding: EdgeInsets.only(top: textTopInset),
                        child: CallbackShortcuts(
                          bindings: M3EFocus.editableInputShortcuts(
                            _focusNode,
                          ),
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
                                .withValues(
                                  alpha: fieldTheme.selectionOpacity,
                                ),
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

/// Widgetbook demo with local tag list.
class Md3eTagInputFieldPreview extends StatefulWidget {
  const Md3eTagInputFieldPreview({super.key});

  @override
  State<Md3eTagInputFieldPreview> createState() =>
      _Md3eTagInputFieldPreviewState();
}

class _Md3eTagInputFieldPreviewState extends State<Md3eTagInputFieldPreview> {
  final List<String> _tags = <String>['深海', '图书馆'];

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Align(
        alignment: Alignment.topCenter,
        child: Md3eTagInputField(
          label: '标签',
          tags: _tags,
          onTagRemoved: (String tag) {
            setState(() => _tags.remove(tag));
          },
          onTagCommitted: (String tag) {
            if (_tags.contains(tag)) {
              return;
            }
            setState(() => _tags.add(tag));
          },
        ),
      ),
    );
  }
}
