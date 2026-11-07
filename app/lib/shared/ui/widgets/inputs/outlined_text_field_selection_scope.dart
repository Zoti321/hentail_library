import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/components/text_fields/components/m3e_text_field_selection_builder.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';

/// Wraps [OutlinedTextFieldShell] like [M3ETextField]'s selection gestures.
class OutlinedTextFieldSelectionScope extends StatefulWidget {
  const OutlinedTextFieldSelectionScope({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.enabled,
    required this.editableTextKey,
    required this.child,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final bool enabled;
  final GlobalKey<EditableTextState> editableTextKey;
  final Widget child;

  @override
  State<OutlinedTextFieldSelectionScope> createState() =>
      _OutlinedTextFieldSelectionScopeState();
}

class _OutlinedTextFieldSelectionScopeState
    extends State<OutlinedTextFieldSelectionScope>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late final M3ETextFieldSelectionBuilder _selectionBuilder =
      M3ETextFieldSelectionBuilder(delegate: this);

  @override
  GlobalKey<EditableTextState> get editableTextKey => widget.editableTextKey;

  @override
  bool get forcePressEnabled =>
      m3eTextFieldForcePressEnabled(defaultTargetPlatform);

  @override
  bool get selectionEnabled => widget.enabled;

  @override
  Widget build(BuildContext context) {
    return _selectionBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
