import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail_md3e/comic_detail_page_entry.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_metadata_section.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Widgetbook 元数据区独立切片。
class Md3eComicDetailMetadataTagsSection extends StatelessWidget {
  const Md3eComicDetailMetadataTagsSection({super.key, required this.entry});

  final Md3eComicDetailEntry entry;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Md3eComicDetailMetadataSection(entry: entry),
    );
  }
}
