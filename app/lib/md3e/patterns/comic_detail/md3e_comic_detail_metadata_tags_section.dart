import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_page_preview_data.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_metadata_section.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Widgetbook 元数据区独立切片。
class Md3eComicDetailMetadataTagsSection extends StatelessWidget {
  const Md3eComicDetailMetadataTagsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Md3eComicDetailMetadataSection(
        entry: Md3eComicDetailPagePreviewData.sample(),
      ),
    );
  }
}
