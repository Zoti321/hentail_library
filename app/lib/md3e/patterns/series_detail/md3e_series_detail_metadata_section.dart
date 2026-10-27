import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_detail_metadata_chip_rows.dart';

/// 系列元数据 chip 区。
class Md3eSeriesDetailMetadataSection extends StatelessWidget {
  const Md3eSeriesDetailMetadataSection({
    super.key,
    required this.entry,
    this.onChipTap,
  });

  final Md3eSeriesDetailEntry entry;
  final ValueChanged<String>? onChipTap;

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
    );
  }
}
