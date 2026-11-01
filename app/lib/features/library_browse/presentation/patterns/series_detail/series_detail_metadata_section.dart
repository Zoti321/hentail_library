import 'package:flutter/material.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_md3e/series_detail_page_entry.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_metadata_chip_rows.dart';

/// 系列元数据 chip 区。
class Md3eSeriesDetailMetadataSection extends StatelessWidget {
  const Md3eSeriesDetailMetadataSection({
    super.key,
    required this.entry,
    this.onChipTap,
    this.onAuthorTap,
  });

  final Md3eSeriesDetailEntry entry;
  final ValueChanged<String>? onChipTap;
  final ValueChanged<String>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    if (!entry.showMetadataBlock) {
      return const SizedBox.shrink();
    }
    return Md3eDetailMetadataChipRows(
      parodies: entry.parodies,
      authors: entry.authors,
      characters: entry.characters,
      tags: entry.tags,
      onChipTap: onChipTap,
      onAuthorTap: onAuthorTap,
    );
  }
}
