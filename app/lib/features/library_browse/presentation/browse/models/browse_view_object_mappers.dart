import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_browse_view_object.dart';
import 'package:hentai_library/features/comic/public/comic.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';

/// Mirrors Rust `compare_filename_natural` for mapper-side Tag preview.
int _compareNatural(String a, String b) {
  final List<String> aParts = _splitNatural(a);
  final List<String> bParts = _splitNatural(b);
  final int n = aParts.length < bParts.length ? aParts.length : bParts.length;
  for (int i = 0; i < n; i++) {
    final String ap = aParts[i];
    final String bp = bParts[i];
    final int? an = int.tryParse(ap);
    final int? bn = int.tryParse(bp);
    if (an != null && bn != null) {
      final int cmp = an.compareTo(bn);
      if (cmp != 0) {
        return cmp;
      }
    } else {
      final int cmp = ap.compareTo(bp);
      if (cmp != 0) {
        return cmp;
      }
    }
  }
  return aParts.length.compareTo(bParts.length);
}

List<String> _splitNatural(String s) {
  final List<String> parts = <String>[];
  final StringBuffer current = StringBuffer();
  bool? wasDigit;
  for (final int unit in s.runes) {
    final String ch = String.fromCharCode(unit);
    final bool isDigit = unit >= 0x30 && unit <= 0x39;
    if (current.isNotEmpty && wasDigit != null && isDigit != wasDigit) {
      parts.add(current.toString());
      current.clear();
    }
    current.write(ch);
    wasDigit = isDigit;
  }
  if (current.isNotEmpty) {
    parts.add(current.toString());
  }
  return parts;
}

List<String> _topNaturalTagNames(Comic comic) {
  final List<String> names = comic.tags
      .map((Tag tag) => tag.name)
      .toList(growable: true);
  names.sort(_compareNatural);
  if (names.length <= 3) {
    return List<String>.unmodifiable(names);
  }
  return List<String>.unmodifiable(names.take(3));
}

ComicBrowseViewObject comicBrowseViewObjectFromComic(Comic comic) {
  return (
    comicId: comic.comicId,
    title: comic.title,
    pageCount: comic.pageCount,
    path: comic.path,
    tagNames: _topNaturalTagNames(comic),
  );
}
