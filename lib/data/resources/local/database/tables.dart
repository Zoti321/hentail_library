import 'package:drift/drift.dart';
import 'dart:convert';

import 'package:hentai_library/domain/util/enums.dart';

// 用户保存的文件系统路径
class SavedPaths extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawPath => text().unique()();

  // 针对 macOS/iOS 的安全凭证，Android 可能是 Tree Document URI
  TextColumn get securityBookmark => text().nullable()();
}

// 阅读历史
@TableIndex(name: 'idx_read_time', columns: {#lastReadTime})
class ReadingHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get comicId => text().unique()();

  // 漫画标题/封面等（冗余存储减少关联查询）
  TextColumn get title => text()();
  TextColumn get coverUrl => text().nullable()();

  DateTimeColumn get lastReadTime => dateTime()();

  // 阅读进度：章节 id、1-based 页码（nullable 兼容旧数据）
  TextColumn get chapterId => text().nullable()();
  IntColumn get pageIndex => integer().nullable()();
}

class StringListJsonConverter extends TypeConverter<List<String>, String> {
  const StringListJsonConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return const <String>[];
    return decoded.whereType<String>().toList();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class LibraryComics extends Table {
  TextColumn get comicId => text()();
  TextColumn get path => text()();
  TextColumn get resourceType => textEnum<ResourceType>()();
  TextColumn get title => text()();
  TextColumn get authorsJson => text()
      .map(const StringListJsonConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get contentRating =>
      textEnum<ContentRating>().withDefault(const Constant('unknown'))();
  IntColumn get pageCount => integer().nullable()();

  @override
  Set<Column> get primaryKey => {comicId};
}

class LibraryTags extends Table {
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {name};
}

class LibraryComicTags extends Table {
  TextColumn get comicId => text()();
  TextColumn get tagName => text()();

  @override
  Set<Column> get primaryKey => {comicId, tagName};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY(comic_id) REFERENCES library_comics(comic_id) ON DELETE CASCADE',
    'FOREIGN KEY(tag_name) REFERENCES library_tags(name) ON DELETE CASCADE',
  ];
}

class LibrarySeries extends Table {
  TextColumn get name => text().unique()();

  @override
  Set<Column> get primaryKey => {name};
}

class LibrarySeriesItems extends Table {
  TextColumn get seriesName => text()();
  TextColumn get comicId => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {seriesName, comicId};

  @override
  List<String> get customConstraints => [
    'UNIQUE(comic_id)',
    'FOREIGN KEY(series_name) REFERENCES library_series(name) ON DELETE CASCADE',
  ];
}
