import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_meta_chip_row.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列元数据 chip 区（Parody → Author → Character → Tag）。
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
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final List<Widget> rows = <Widget>[];

    void addChipRow(String label, List<String> items) {
      if (items.isEmpty) {
        return;
      }
      rows.add(
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

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.md,
      children: rows,
    );
  }
}
