import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_info_row.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_meta_chip_row.dart';
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
    final List<Widget> chipRows = <Widget>[];
    final List<Widget> infoRows = <Widget>[];

    void addChipRow(String label, List<String> items) {
      if (items.isEmpty) {
        return;
      }
      chipRows.add(
        Md3eComicDetailMetaChipRow(
          label: label,
          items: items,
          onItemTap: onChipTap,
        ),
      );
    }

    addChipRow(l10n.comicDetailParodies, entry.parodies);
    addChipRow(l10n.comicDetailAuthors, entry.authors);
    addChipRow(l10n.comicDetailCharacters, entry.characters);
    addChipRow(l10n.comicDetailTags, entry.tags);

    infoRows.addAll(<Widget>[
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
    ]);

    final double tagsToResourceGap =
        Md3eComicDetailPageMetrics.metadataTagsToResourceSpacing(sizeClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (chipRows.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing.md,
            children: chipRows,
          ),
        if (chipRows.isNotEmpty && infoRows.isNotEmpty)
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
