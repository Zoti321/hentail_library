import 'package:drift/drift.dart';
import 'package:hentai_library/domain/enums/enums.dart';

// 漫画
class Comics extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get comicId => text().unique()();

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get status => text().nullable()();

  DateTimeColumn get firstPublishedAt => dateTime().nullable()();
  DateTimeColumn get lastUpdatedAt => dateTime().nullable()();

  BoolColumn get isR18 => boolean().withDefault(const Constant(false))();

  IntColumn get totalViews => integer().withDefault(const Constant(0))();
}

// 章节
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get chapterId => text().unique()(); // 业务唯一ID
  TextColumn get comicId => text().references(
    Comics,
    #comicId,
    onDelete: KeyAction.cascade,
  )(); // 所属漫画ID

  IntColumn get number => integer().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  IntColumn get pageCount => integer().nullable()();

  TextColumn get imageDir => text().nullable().unique()();

  /// 原始图源路径（EPUB 文件路径或文件夹路径），用于缓存被清理后重新提取
  TextColumn get sourcePath => text().nullable()();
}

// 分类标签
class CategoryTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get type => textEnum<CategoryTagType>().withDefault(
    const Constant('tag'),
  )(); // author,character,tag,series
  BoolColumn get isR18 => boolean().withDefault(const Constant(false))();

  List<Index> get indexes => [Index('idx_category_tags_name', 'name')];
}

// 漫画-标签 关联表
class ComicTags extends Table {
  @override
  Set<Column> get primaryKey => {comicId, tagId};

  TextColumn get comicId =>
      text().references(Comics, #comicId, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(CategoryTags, #id, onDelete: KeyAction.cascade)();

  List<Index> get indexes => [
    Index('idx_comic_tags_comic', 'comic_id'),
    Index('idx_comic_tags_tag', 'tag_id'),
  ];
}

// 选中的文件目录
class SelectedDirectories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawPath => text().unique()();

  // 针对 macOS/iOS 的安全凭证，Android 可能是 Tree Document URI
  TextColumn get securityBookmark => text().nullable()();
}

// 阅读历史
@TableIndex(name: 'idx_read_time', columns: {#lastReadTime})
class ReadingHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get comicId => text()
      .references(Comics, #comicId, onDelete: KeyAction.cascade)
      .unique()();

  // 漫画标题/封面等（冗余存储减少关联查询）
  TextColumn get title => text()();
  TextColumn get coverUrl => text().nullable()();

  DateTimeColumn get lastReadTime => dateTime()();

  // 阅读进度：章节 id、1-based 页码（nullable 兼容旧数据）
  TextColumn get chapterId => text().nullable()();
  IntColumn get pageIndex => integer().nullable()();
}

// 阅读会话（用于统计每日阅读时长）
@TableIndex(name: 'idx_session_date', columns: {#date})
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get comicId =>
      text().references(Comics, #comicId, onDelete: KeyAction.cascade)();

  /// 会话日期（当天 0 点，便于按日聚合）
  DateTimeColumn get date => dateTime()();

  IntColumn get durationSeconds => integer()();
}
