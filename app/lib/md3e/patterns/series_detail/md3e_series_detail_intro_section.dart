import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_series_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_metadata_section.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_primary_block.dart';

/// 系列详情滚动区上部：主信息 + 元数据。
class Md3eSeriesDetailIntroSection extends StatelessWidget {
  const Md3eSeriesDetailIntroSection({
    super.key,
    required this.entry,
    this.onMetadataChipTap,
  });

  final Md3eSeriesDetailEntry entry;
  final ValueChanged<String>? onMetadataChipTap;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double primaryToMeta =
        Md3eSeriesDetailPageMetrics.primaryToMetadataSpacing(sizeClass);
    final double beforeComics =
        Md3eSeriesDetailPageMetrics.metadataToComicsSpacing(sizeClass);
    final bool showMeta = entry.showMetadataBlock && _hasMetadataChips(entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eSeriesDetailPrimaryBlock(entry: entry),
        if (showMeta) ...<Widget>[
          SizedBox(height: primaryToMeta),
          Md3eSeriesDetailMetadataSection(
            entry: entry,
            onChipTap: onMetadataChipTap,
          ),
        ],
        SizedBox(
          height: showMeta
              ? beforeComics
              : Md3eSeriesDetailPageMetrics.comicsSectionTopSpacing(sizeClass),
        ),
      ],
    );
  }

  static bool _hasMetadataChips(Md3eSeriesDetailEntry entry) {
    return entry.parodies.isNotEmpty ||
        entry.authors.isNotEmpty ||
        entry.characters.isNotEmpty ||
        entry.tags.isNotEmpty;
  }
}
