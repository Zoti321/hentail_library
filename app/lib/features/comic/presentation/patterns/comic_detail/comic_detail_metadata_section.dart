import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_info_row.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_metadata_chip_rows.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 元数据区：Parody → Author → Character → Tag + 资源 KV 行。
class ComicDetailMetadataSection extends StatelessWidget {
  const ComicDetailMetadataSection({
    super.key,
    required this.entry,
    this.onChipTap,
    this.onAuthorTap,
  });

  final ComicDetailViewObject entry;
  final ValueChanged<String>? onChipTap;
  final ValueChanged<String>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);

    final Widget chipBlock = DetailMetadataChipRows(
      parodies: entry.parodies,
      authors: entry.authors,
      characters: entry.characters,
      tags: entry.tags,
      onChipTap: onChipTap,
      onAuthorTap: onAuthorTap,
    );

    final List<Widget> infoRows = <Widget>[
      ComicDetailInfoRow(
        label: l10n.comicDetailResourceFormat,
        value: entry.resourceFormat,
      ),
      ComicDetailInfoRow(
        label: l10n.comicDetailResourceSize,
        value: entry.resourceSizeLabel,
      ),
      ComicDetailInfoRow(
        label: l10n.comicDetailResourcePath,
        value: entry.resourcePath,
        tooltip: entry.resourcePath,
      ),
      if (entry.addedAtLabel != null)
        ComicDetailInfoRow(
          label: l10n.comicDetailAddedAt,
          value: entry.addedAtLabel!,
        ),
      if (entry.updatedAtLabel != null)
        ComicDetailInfoRow(
          label: l10n.comicDetailUpdatedAt,
          value: entry.updatedAtLabel!,
        ),
    ];

    final double tagsToResourceGap =
        ComicDetailPageMetrics.metadataTagsToResourceSpacing(sizeClass);
    final bool hasChips =
        entry.parodies.isNotEmpty ||
        entry.authors.isNotEmpty ||
        entry.characters.isNotEmpty ||
        entry.tags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        chipBlock,
        if (hasChips && infoRows.isNotEmpty)
          SizedBox(height: tagsToResourceGap),
        if (infoRows.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing.md,
            children: infoRows,
          ),
      ],
    );
  }
}
