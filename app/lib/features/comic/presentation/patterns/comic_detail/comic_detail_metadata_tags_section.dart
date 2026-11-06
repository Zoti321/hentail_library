import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_metadata_section.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Widgetbook 元数据区独立切片。
class ComicDetailMetadataTagsSection extends StatelessWidget {
  const ComicDetailMetadataTagsSection({super.key, required this.entry});

  final ComicDetailViewObject entry;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: ComicDetailMetadataSection(entry: entry),
    );
  }
}
