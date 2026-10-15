import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';

/// 把旧版按显示名持久化的 Author 筛选迁到 id；匹配失败的项丢弃。
LibraryMetadataFilterSelection migrateAuthorFilterPreference({
  required List<String>? includeIds,
  required List<String>? excludeIds,
  required List<String>? legacyIncludeNames,
  required List<String>? legacyExcludeNames,
  required String? includeModeName,
  required List<Author> authors,
}) {
  if (includeIds != null || excludeIds != null) {
    return LibraryMetadataFilterSelection.fromStorage(
      includeNames: includeIds,
      excludeNames: excludeIds,
      includeModeName: includeModeName,
    );
  }
  final Map<String, String> nameToId = <String, String>{
    for (final Author author in authors)
      if (author.id != null) author.name: '${author.id}',
  };
  List<String> mapNames(List<String>? names) {
    final List<String> ids = <String>[];
    for (final String name in names ?? const <String>[]) {
      final String? id = nameToId[name];
      if (id != null) {
        ids.add(id);
      }
    }
    return ids;
  }

  return LibraryMetadataFilterSelection.fromStorage(
    includeNames: mapNames(legacyIncludeNames),
    excludeNames: mapNames(legacyExcludeNames),
    includeModeName: includeModeName,
  );
}
