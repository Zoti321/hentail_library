import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Widgetbook demo with local tag list.
class Md3eTagInputFieldPreview extends StatefulWidget {
  const Md3eTagInputFieldPreview({super.key});

  @override
  State<Md3eTagInputFieldPreview> createState() =>
      _Md3eTagInputFieldPreviewState();
}

class _Md3eTagInputFieldPreviewState extends State<Md3eTagInputFieldPreview> {
  final List<String> _tags = <String>['深海', '图书馆'];

  void _handleTagRemoved(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _handleTagCommitted(String tag) {
    if (_tags.contains(tag)) {
      return;
    }
    setState(() => _tags.add(tag));
  }

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Align(
        alignment: Alignment.topCenter,
        child: TagInputField(
          label: '标签',
          tags: _tags,
          onTagRemoved: _handleTagRemoved,
          onTagCommitted: _handleTagCommitted,
        ),
      ),
    );
  }
}
