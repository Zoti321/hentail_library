import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_info_row.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_detail_metadata_chip_rows.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 元数据区：Parody → Author → Character → Tag + 资源 KV 行。
class Md3eComicDetailMetadataSection extends StatelessWidget {
  const Md3eComicDetailMetadataSection({
    super.key,
    required this.entry,
    this.onChipTap,
  });

  final Md3eComicDetailEntry entry;
  final ValueChanged<String>? onChipTap;

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
    final bool hasChips = entry.parodies.isNotEmpty ||
        entry.authors.isNotEmpty ||
        entry.characters.isNotEmpty ||
        entry.tags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        chipBlock,
        if (hasChips && infoRows.isNotEmpty) SizedBox(height: tagsToResourceGap),
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
