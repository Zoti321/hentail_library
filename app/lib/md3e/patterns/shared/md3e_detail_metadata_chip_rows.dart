import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_meta_chip_row.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Parody → Author → Character → Tag（漫画 / 系列详情共用）。
class Md3eDetailMetadataChipRows extends StatelessWidget {
  const Md3eDetailMetadataChipRows({
    super.key,
    this.parodies = const <String>[],
    this.authors = const <String>[],
    this.characters = const <String>[],
    this.tags = const <String>[],
    this.onChipTap,
  });

  final List<String> parodies;
  final List<String> authors;
  final List<String> characters;
  final List<String> tags;
  final ValueChanged<String>? onChipTap;

  bool get isEmpty =>
      parodies.isEmpty &&
      authors.isEmpty &&
      characters.isEmpty &&
      tags.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final List<Widget> rows = <Widget>[];

    void addRow(String label, List<String> items) {
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

    addRow(l10n.comicDetailParodies, parodies);
    addRow(l10n.comicDetailAuthors, authors);
    addRow(l10n.comicDetailCharacters, characters);
    addRow(l10n.comicDetailTags, tags);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.md,
      children: rows,
    );
  }
}
