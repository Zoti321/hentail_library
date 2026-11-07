import 'package:flutter/material.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_metadata_chip_rows.dart';

/// 系列元数据 chip 区。
class SeriesDetailMetadataSection extends StatelessWidget {
  const SeriesDetailMetadataSection({
    super.key,
    required this.entry,
    this.onChipTap,
    this.onAuthorTap,
  });

  final SeriesDetailViewObject entry;
  final ValueChanged<String>? onChipTap;
  final ValueChanged<String>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    if (!entry.showMetadataBlock) {
      return const SizedBox.shrink();
    }
    return DetailMetadataChipRows(
      parodies: entry.parodies,
      authors: entry.authors,
      characters: entry.characters,
      tags: entry.tags,
      onChipTap: onChipTap,
      onAuthorTap: onAuthorTap,
    );
  }
}
