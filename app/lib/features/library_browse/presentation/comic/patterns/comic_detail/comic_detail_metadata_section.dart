import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/views/comic_detail_md3e/comic_detail_page_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/patterns/comic_detail/comic_detail_info_row.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_metadata_chip_rows.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 元数据区：Parody → Author → Character → Tag + 资源 KV 行。
class Md3eComicDetailMetadataSection extends StatelessWidget {
  const Md3eComicDetailMetadataSection({
    super.key,
    required this.entry,
    this.onChipTap,
    this.onAuthorTap,
  });

  final Md3eComicDetailEntry entry;
  final ValueChanged<String>? onChipTap;
  final ValueChanged<String>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);

    final Widget chipBlock = Md3eDetailMetadataChipRows(
      parodies: entry.parodies,
      authors: entry.authors,
      characters: entry.characters,
      tags: entry.tags,
      onChipTap: onChipTap,
      onAuthorTap: onAuthorTap,
    );

    final List<Widget> infoRows = <Widget>[
      Md3eComicDetailInfoRow(
        label: l10n.comicDetailResourceFormat,
        value: entry.resourceFormat,
      ),
      Md3eComicDetailInfoRow(
        label: l10n.comicDetailResourceSize,
        value: entry.resourceSizeLabel,
      ),
      Md3eComicDetailInfoRow(
        label: l10n.comicDetailResourcePath,
        value: entry.resourcePath,
        tooltip: entry.resourcePath,
      ),
      if (entry.addedAtLabel != null)
        Md3eComicDetailInfoRow(
          label: l10n.comicDetailAddedAt,
          value: entry.addedAtLabel!,
        ),
      if (entry.updatedAtLabel != null)
        Md3eComicDetailInfoRow(
          label: l10n.comicDetailUpdatedAt,
          value: entry.updatedAtLabel!,
        ),
    ];

    final double tagsToResourceGap =
        Md3eComicDetailPageMetrics.metadataTagsToResourceSpacing(sizeClass);
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
