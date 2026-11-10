import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/shared/ui/patterns/comic_detail/comic_detail_meta_chip_row.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Parody → Author → Character → Tag（漫画 / 系列详情共用）。
class DetailMetadataChipRows extends StatelessWidget {
  const DetailMetadataChipRows({
    super.key,
    this.parodies = const <String>[],
    this.authors = const <AuthorRef>[],
    this.characters = const <String>[],
    this.tags = const <String>[],
    this.onChipTap,
    this.onAuthorTap,
  });

  final List<String> parodies;
  final List<AuthorRef> authors;
  final List<String> characters;
  final List<String> tags;
  final ValueChanged<String>? onChipTap;

  /// 作者 chip 点击（生产：打开作者详情）；为空时与其它 chip 一样走 [onChipTap]。
  final ValueChanged<AuthorRef>? onAuthorTap;

  bool get isEmpty =>
      parodies.isEmpty && authors.isEmpty && characters.isEmpty && tags.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final List<Widget> rows = <Widget>[];

    void addRow<T>(
      String label,
      List<T> items, {
      String Function(T item)? labelOf,
      ValueChanged<T>? onTap,
    }) {
      if (items.isEmpty) {
        return;
      }
      rows.add(
        ComicDetailMetaChipRow<T>(
          label: label,
          items: items,
          labelOf: labelOf,
          onItemTap: onTap,
        ),
      );
    }

    addRow<String>(l10n.comicDetailParodies, parodies, onTap: onChipTap);
    addRow<AuthorRef>(
      l10n.comicDetailAuthors,
      authors,
      labelOf: (AuthorRef a) => a.name,
      // 未注入作者点击时回退到通用 chip 回调（按显示名）。
      onTap:
          onAuthorTap ??
          (onChipTap == null ? null : (AuthorRef a) => onChipTap!(a.name)),
    );
    addRow<String>(l10n.comicDetailCharacters, characters, onTap: onChipTap);
    addRow<String>(l10n.comicDetailTags, tags, onTap: onChipTap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.md,
      children: rows,
    );
  }
}
