import 'package:pinyin_pro_flutter/pinyin_pro_flutter.dart';

final RegExp _cjkInQuery = RegExp(
  r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]',
);

final RegExp _toneDigitsOrSpace = RegExp(r'[\s1-5]');

final RegExp _toneMarkVowels = RegExp(
  r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü]',
);

const Map<String, String> _toneMarkToAscii = <String, String>{
  'ā': 'a',
  'á': 'a',
  'ǎ': 'a',
  'à': 'a',
  'ē': 'e',
  'é': 'e',
  'ě': 'e',
  'è': 'e',
  'ī': 'i',
  'í': 'i',
  'ǐ': 'i',
  'ì': 'i',
  'ō': 'o',
  'ó': 'o',
  'ǒ': 'o',
  'ò': 'o',
  'ū': 'u',
  'ú': 'u',
  'ǔ': 'u',
  'ù': 'u',
  'ǖ': 'v',
  'ǘ': 'v',
  'ǚ': 'v',
  'ǜ': 'v',
  'ü': 'v',
};

/// Pinyin-assisted name match for Named metadata facet display names.
///
/// Trims [rawQuery]; empty / whitespace-only means match-all.
/// Latin queries also match tone-less full pinyin or initials substrings.
/// Queries containing CJK only use display-name substring.
bool nameMatchesPinyinAssistedFilter(String name, String rawQuery) {
  final String query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return true;
  }
  if (name.toLowerCase().contains(query)) {
    return true;
  }
  if (_cjkInQuery.hasMatch(query)) {
    return false;
  }

  final String latinQuery = _normalizeLatinPinyinQuery(query);
  if (latinQuery.isEmpty) {
    // Non-empty query that was only tones/spaces: no Latin key left to match.
    return false;
  }

  final String fullPinyin = pinyin(
    name,
    options: const PinyinOptions(
      toneType: ToneType.none,
      separator: '',
      v: true,
    ),
  ).toLowerCase();
  if (fullPinyin.contains(latinQuery)) {
    return true;
  }

  final String initials = pinyin(
    name,
    options: const PinyinOptions(
      pattern: PinyinPattern.first,
      separator: '',
      v: true,
    ),
  ).toLowerCase();
  return initials.contains(latinQuery);
}

String _normalizeLatinPinyinQuery(String query) {
  return query
      .replaceAll(_toneDigitsOrSpace, '')
      .replaceAllMapped(
        _toneMarkVowels,
        (Match match) => _toneMarkToAscii[match.group(0)!] ?? match.group(0)!,
      );
}
