import 'package:flutter/material.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_page_metrics.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_metadata_section.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_primary_block.dart';

/// 系列详情滚动区上部：主信息 + 元数据。
class SeriesDetailIntroSection extends StatelessWidget {
  const SeriesDetailIntroSection({
    super.key,
    required this.entry,
    this.onMetadataChipTap,
    this.onAuthorTap,
  });

  final SeriesDetailViewObject entry;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<AuthorRef>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double primaryToMeta =
        SeriesDetailPageMetrics.primaryToMetadataSpacing(sizeClass);
    final double beforeComics = SeriesDetailPageMetrics.metadataToComicsSpacing(
      sizeClass,
    );
    final bool showMeta = entry.showMetadataBlock && _hasMetadataChips(entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SeriesDetailPrimaryBlock(entry: entry),
        if (showMeta) ...<Widget>[
          SizedBox(height: primaryToMeta),
          SeriesDetailMetadataSection(
            entry: entry,
            onChipTap: onMetadataChipTap,
            onAuthorTap: onAuthorTap,
          ),
        ],
        SizedBox(
          height: showMeta
              ? beforeComics
              : SeriesDetailPageMetrics.comicsSectionTopSpacing(sizeClass),
        ),
      ],
    );
  }

  static bool _hasMetadataChips(SeriesDetailViewObject entry) {
    return entry.parodies.isNotEmpty ||
        entry.authors.isNotEmpty ||
        entry.characters.isNotEmpty ||
        entry.tags.isNotEmpty;
  }
}
