import 'dart:isolate';

import 'package:pinyin_pro_flutter/pinyin_pro_flutter.dart';

final RegExp _cjkInQuery = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');

final RegExp _toneDigitsOrSpace = RegExp(r'[\s1-5]');

final RegExp _toneMarkVowels = RegExp(r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü]');

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

/// Below this size, build on the UI isolate (spawn cost dominates).
const int kNamePinyinIndexIsolateThreshold = 64;

/// Precomputed Latin keys for one display name.
class NamePinyinIndexEntry {
  const NamePinyinIndexEntry({
    required this.name,
    required this.nameLower,
    required this.fullPinyin,
    required this.initials,
  });

  final String name;
  final String nameLower;
  final String fullPinyin;
  final String initials;
}

/// Dictionary of [NamePinyinIndexEntry] for O(n) contains-only filtering.
class NamePinyinIndex {
  NamePinyinIndex(List<NamePinyinIndexEntry> entries)
    : _byName = <String, NamePinyinIndexEntry>{
        for (final NamePinyinIndexEntry entry in entries) entry.name: entry,
      };

  final Map<String, NamePinyinIndexEntry> _byName;

  int get length => _byName.length;

  bool matches(String name, String rawQuery) {
    final String query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final NamePinyinIndexEntry? entry = _byName[name];
    if (entry == null) {
      return nameMatchesPinyinAssistedFilter(name, rawQuery);
    }
    return namePinyinIndexEntryMatches(entry, query);
  }
}

/// Build pinyin keys for [names]. Large lists use [Isolate.run].
Future<NamePinyinIndex> buildNamePinyinIndex(List<String> names) async {
  if (names.isEmpty) {
    return NamePinyinIndex(const <NamePinyinIndexEntry>[]);
  }
  if (names.length < kNamePinyinIndexIsolateThreshold) {
    return NamePinyinIndex(buildNamePinyinIndexEntries(names));
  }
  final List<NamePinyinIndexEntry> entries = await Isolate.run(
    () => buildNamePinyinIndexEntries(names),
  );
  return NamePinyinIndex(entries);
}

/// Pure CPU entry builder (top-level for [Isolate.run]).
List<NamePinyinIndexEntry> buildNamePinyinIndexEntries(List<String> names) {
  return <NamePinyinIndexEntry>[
    for (final String name in names) buildNamePinyinIndexEntry(name),
  ];
}

NamePinyinIndexEntry buildNamePinyinIndexEntry(String name) {
  return NamePinyinIndexEntry(
    name: name,
    nameLower: name.toLowerCase(),
    fullPinyin: pinyin(
      name,
      options: const PinyinOptions(
        toneType: ToneType.none,
        separator: '',
        v: true,
      ),
    ).toLowerCase(),
    initials: pinyin(
      name,
      options: const PinyinOptions(
        pattern: PinyinPattern.first,
        separator: '',
        v: true,
      ),
    ).toLowerCase(),
  );
}

/// Match against a pre-normalized lowercase [query] (already trimmed).
bool namePinyinIndexEntryMatches(NamePinyinIndexEntry entry, String query) {
  if (query.isEmpty) {
    return true;
  }
  if (entry.nameLower.contains(query)) {
    return true;
  }
  if (_cjkInQuery.hasMatch(query)) {
    return false;
  }

  final String latinQuery = normalizeLatinPinyinQuery(query);
  if (latinQuery.isEmpty) {
    return false;
  }
  return entry.fullPinyin.contains(latinQuery) ||
      entry.initials.contains(latinQuery);
}

/// Pinyin-assisted name match for Named metadata facet display names.
///
/// Trims [rawQuery]; empty / whitespace-only means match-all.
/// Latin queries also match tone-less full pinyin or initials substrings.
/// Queries containing CJK only use display-name substring.
///
/// Prefer [NamePinyinIndex] when filtering many names repeatedly.
bool nameMatchesPinyinAssistedFilter(String name, String rawQuery) {
  final String query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return true;
  }
  return namePinyinIndexEntryMatches(buildNamePinyinIndexEntry(name), query);
}

String normalizeLatinPinyinQuery(String query) {
  return query
      .replaceAll(_toneDigitsOrSpace, '')
      .replaceAllMapped(
        _toneMarkVowels,
        (Match match) => _toneMarkToAscii[match.group(0)!] ?? match.group(0)!,
      );
}
