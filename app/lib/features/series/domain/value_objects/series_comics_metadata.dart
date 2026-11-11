import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

/// 系列内漫画聚合元数据（作者、标签、Language / Parody / Character、R18）。
class SeriesComicsMetadata {
  const SeriesComicsMetadata({
    required this.authors,
    required this.tags,
    required this.hasR18,
    this.languages = const <String>[],
    this.parodies = const <String>[],
    this.characters = const <String>[],
  });

  /// 成员 Comic 的 Author 引用投影（按 id 去重）。
  final List<AuthorRef> authors;
  final List<String> tags;
  final bool hasR18;

  /// 成员顺序 + first-seen 去重后的 Language 列表。
  final List<String> languages;

  /// 成员顺序 + first-seen 去重后的 Parody 列表。
  final List<String> parodies;

  /// 成员顺序 + first-seen 去重后的 Character 列表。
  final List<String> characters;

  bool get hasMetadataBlock =>
      parodies.isNotEmpty ||
      authors.isNotEmpty ||
      characters.isNotEmpty ||
      tags.isNotEmpty;
}
