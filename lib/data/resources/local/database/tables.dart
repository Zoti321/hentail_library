import 'package:drift/drift.dart';
import 'dart:convert';

import 'package:hentai_library/domain/util/enums.dart';

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

@DataClassName('DbComic')
class Comics extends Table {
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

@DataClassName('DbTag')
class Tags extends Table {
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {name};
}

@DataClassName('DbComicTag')
class ComicTags extends Table {
  TextColumn get comicId => text()();
  TextColumn get tagName => text()();

  @override
  Set<Column> get primaryKey => {comicId, tagName};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE',
    'FOREIGN KEY(tag_name) REFERENCES tags(name) ON DELETE CASCADE',
  ];
}

@DataClassName('DbSeries')
class SeriesTable extends Table {
  @override
  String get tableName => 'series';

  TextColumn get name => text().unique()();

  @override
  Set<Column> get primaryKey => {name};
}

@DataClassName('DbSeriesItem')
class SeriesItems extends Table {
  TextColumn get seriesName => text()();
  TextColumn get comicId => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {seriesName, comicId};

  @override
  List<String> get customConstraints => [
    'UNIQUE(comic_id)',
    'FOREIGN KEY(series_name) REFERENCES series(name) ON DELETE CASCADE ON UPDATE CASCADE',
    'FOREIGN KEY(comic_id) REFERENCES comics(comic_id) ON DELETE CASCADE ON UPDATE CASCADE',
  ];
}

// 用户保存的文件系统路径
class SavedPaths extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawPath => text().unique()();

  // 针对 macOS/iOS 的安全凭证，Android 可能是 Tree Document URI
  TextColumn get securityBookmark => text().nullable()();
}

/// 单本漫画阅读历史（与 [Comic] 标识对齐：comicId、title + 进度）。
@DataClassName('ComicReadingHistoryRow')
@TableIndex(name: 'idx_read_time', columns: {#lastReadTime})
class ComicReadingHistories extends Table {
  TextColumn get comicId => text()();
  TextColumn get title => text()();
  DateTimeColumn get lastReadTime => dateTime()();
  IntColumn get pageIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {comicId};
}

/// 系列维度阅读历史（与 [Series.name] 对齐 + 最后打开的漫画与页码）。
@DataClassName('SeriesReadingHistoryRow')
@TableIndex(name: 'idx_series_read_time', columns: {#lastReadTime})
class SeriesReadingHistories extends Table {
  TextColumn get seriesName => text()();
  TextColumn get lastReadComicId => text()();
  DateTimeColumn get lastReadTime => dateTime()();
  IntColumn get pageIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {seriesName};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY(series_name) REFERENCES series(name) ON DELETE CASCADE ON UPDATE CASCADE',
  ];
}
