import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'database.dart';

part 'dao.g.dart';

// 数据访问层

// 漫画DAO
@DriftAccessor(tables: [Comics, Chapters, CategoryTags, ComicTags])
class ComicDao extends DatabaseAccessor<AppDatabase> with _$ComicDaoMixin {
  ComicDao(super.db);

  Future<List<Comic>> getAllComics() => select(comics).get(); // 获取所有漫画

  Stream<List<Comic>> watchAllComics() => select(comics).watch(); // 监听所有漫画

  Future<List<Chapter>> getAllChapters() => select(chapters).get();

  // 获取所有漫画及其所有章节和标签
  Future<Map<String, ComicWithChaptersAndTags>>
  getComicWithChaptersAndTags() async {
    final allComics = await select(comics).get();
    if (allComics.isEmpty) return {};

    final comicIds = allComics.map((c) => c.comicId).toList();

    final results = await Future.wait([
      (select(chapters)..where((t) => t.comicId.isIn(comicIds))).get(),
      (select(comicTags).join([
        innerJoin(categoryTags, categoryTags.id.equalsExp(comicTags.tagId)),
      ])..where(comicTags.comicId.isIn(comicIds))).get(),
    ]);

    final allChapters = results[0] as List<Chapter>;
    final tagRows = results[1] as List<TypedResult>;

    final groupMap = {
      for (var comic in allComics)
        comic.comicId: ComicWithChaptersAndTags(
          comic: comic,
          chapters: {},
          tags: {},
        ),
    };

    // 4. 将章节分配到对应的漫画对象中
    for (final chapter in allChapters) {
      groupMap[chapter.comicId]?.chapters.add(chapter);
    }

    // 5. 将标签分配到对应的漫画对象中
    for (final row in tagRows) {
      final tag = row.readTable(categoryTags);
      final comicId = row.readTable(comicTags).comicId;
      groupMap[comicId]?.tags.add(tag);
    }

    return groupMap;
  }

  /// 监听 comics、chapters、comic_tags 任一表变更，触发聚合查询
  Stream<Map<String, ComicWithChaptersAndTags>>
  watchComicWithChaptersAndTags() {
    return StreamGroup.merge([
      select(comics).watch(),
      select(chapters).watch(),
      select(comicTags).watch(),
    ]).asyncMap((_) => getComicWithChaptersAndTags());
  }

  // 根据漫画id获取漫画
  Future<Comic?> getComicById(String comicId) {
    return (select(
      comics,
    )..where((t) => t.comicId.equals(comicId))).getSingleOrNull();
  }

  /// 按 comicId 查询单本漫画聚合（仅该漫画的 chapters、tags），避免全量加载
  Future<ComicWithChaptersAndTags?> getComicWithChaptersAndTagsById(
    String comicId,
  ) async {
    final comic = await getComicById(comicId);
    if (comic == null) return null;

    final results = await Future.wait([
      (select(chapters)..where((t) => t.comicId.equals(comicId))).get(),
      (select(comicTags).join([
        innerJoin(categoryTags, categoryTags.id.equalsExp(comicTags.tagId)),
      ])..where(comicTags.comicId.equals(comicId))).get(),
    ]);

    final chapterList = results[0] as List<Chapter>;
    final tagRows = results[1] as List<TypedResult>;

    final entry = ComicWithChaptersAndTags(
      comic: comic,
      chapters: {for (final c in chapterList) c},
      tags: {for (final row in tagRows) row.readTable(categoryTags)},
    );
    return entry;
  }

  // 搜索漫画
  Future<List<Comic>> searchComics(String query) {
    final pattern = '%$query%';
    return (select(comics)..where((t) => t.title.like(pattern))).get();
  }

  // 插入漫画
  Future<String> insertComic(ComicsCompanion companion) async {
    await into(comics).insert(companion, mode: InsertMode.insertOrIgnore);
    return companion.comicId.value;
  }

  // 批量插入漫画（事务）
  Future<void> batchInsertComics(List<ComicsCompanion> comicList) {
    return transaction(() async {
      await batch((batch) {
        batch.insertAll(comics, comicList, mode: InsertMode.insertOrIgnore);
      });
    });
  }

  // 更新漫画部分字段
  Future<int> updateComicInfo(
    String comicId, {
    String? title,
    String? description,
    bool? isR18,
  }) {
    return (update(comics)..where((t) => t.comicId.equals(comicId))).write(
      ComicsCompanion(
        title: Value.absentIfNull(title),
        description: Value.absentIfNull(description),
        lastUpdatedAt: Value(DateTime.now()),
        isR18: Value.absentIfNull(isR18),
      ),
    );
  }

  // 增加阅读量
  Future<void> incrementViews(String comicId) async {
    final comic = await getComicById(comicId);

    if (comic != null) {
      await update(
        comics,
      ).replace(comic.copyWith(totalViews: comic.totalViews + 1));
    }
  }

  // 删除单本漫画
  Future<int> deleteComic(String comicId) {
    return (delete(comics)..where((t) => t.comicId.equals(comicId))).go();
  }

  // 批量删除漫画
  Future<int> batchDeleteComics(List<String> comicIds) {
    return (delete(comics)..where((t) => t.comicId.isIn(comicIds))).go();
  }

  // 插入漫画章节
  Future<String> insertChapter(ChaptersCompanion companion) async {
    await into(chapters).insert(companion, mode: InsertMode.insertOrIgnore);
    return companion.chapterId.value;
  }

  // 批量插入漫画章节
  Future<void> batchInsertChapters(List<ChaptersCompanion> chapterList) {
    return transaction(() async {
      await batch((batch) {
        batch.insertAll(chapters, chapterList, mode: InsertMode.insertOrIgnore);
      });
    });
  }

  // 删除漫画章节
  Future<int> deleteChapter(String chapterId) {
    return (delete(chapters)..where((t) => t.chapterId.equals(chapterId))).go();
  }

  // 批量删除漫画章节
  Future<int> batchDeleteChapters(List<String> chapterIds) {
    return (delete(chapters)..where((t) => t.chapterId.isIn(chapterIds))).go();
  }

  // 更新章节指向的漫画
  Future<int> updateChapterComic(String chapterId, String comicId) {
    return (update(chapters)..where((t) => t.chapterId.equals(chapterId)))
        .write(ChaptersCompanion(comicId: Value(comicId)));
  }
}

// 分类标签DAO
@DriftAccessor(tables: [CategoryTags, ComicTags])
class CategoryTagDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryTagDaoMixin {
  // 创建查询分类标签
  // 关联分类标签和漫画，同人志

  CategoryTagDao(super.db);

  Future<List<CategoryTag>> getAllTags() => select(categoryTags).get();

  Future<List<CategoryTag>> getR18Tags() =>
      (select(categoryTags)..where((e) => e.isR18.equals(true))).get();

  // 获取漫画的所有标签
  Future<List<CategoryTag>> getComicTags(String comicId) {
    return (select(categoryTags)
          ..join([
            innerJoin(comicTags, comicTags.tagId.equalsExp(categoryTags.id)),
          ])
          ..where((t) => comicTags.comicId.equals(comicId)))
        .get();
  }

  Future<CategoryTag?> getTagByNameAndType(String name, CategoryTagType type) {
    return (select(categoryTags)
          ..where((t) => t.name.equals(name) & t.type.equals(type.name)))
        .getSingleOrNull();
  }

  // 插入新的标签
  Future<int> insertTag(CategoryTagsCompanion companion) {
    return into(categoryTags).insert(
      companion,
      mode: InsertMode.insertOrIgnore,
      onConflict: DoNothing(),
    );
  }

  Future<int> getOrInsertTag(CategoryTagsCompanion companion) async {
    return transaction(() async {
      await into(
        categoryTags,
      ).insert(companion, mode: InsertMode.insertOrIgnore);
      final tag = await getTagByNameAndType(
        companion.name.value,
        companion.type.value,
      );
      return tag!.id;
    });
  }

  // 附着标签到漫画
  Future<int> relateComicTag(String comicId, int tagId) {
    return into(comicTags).insert(
      ComicTagsCompanion.insert(comicId: comicId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
      onConflict: DoNothing(),
    );
  }

  // 批量附着标签到漫画
  Future<void> batchRelateComicTags(String comicId, List<int> tagIds) {
    return transaction(() async {
      await batch((batch) {
        batch.insertAll(
          comicTags,
          tagIds.map(
            (tagId) =>
                ComicTagsCompanion.insert(comicId: comicId, tagId: tagId),
          ),
          mode: InsertMode.insertOrIgnore,
          onConflict: DoNothing(),
        );
      });
    });
  }

  // 剥离漫画的标签
  Future<void> updateComicTags(
    String comicId,
    List<CategoryTagsCompanion> tags,
  ) async {
    return transaction(() async {
      final ids = await Future.wait(tags.map((e) => getOrInsertTag(e)));

      await batch((batch) {
        // 删除漫画的所有标签
        batch.deleteWhere(comicTags, (row) => row.comicId.equals(comicId));

        // 附着标签到漫画
        batch.insertAll(
          comicTags,
          ids.map((e) => ComicTagsCompanion.insert(comicId: comicId, tagId: e)),
          mode: InsertMode.insertOrIgnore,
        );
      });
    });
  }

  // 删除单个标签
  Future<int> deleteTag(int tagId) {
    return (delete(categoryTags)..where((t) => t.id.equals(tagId))).go();
  }
}

// 选择的目录DAO
@DriftAccessor(tables: [SelectedDirectories])
class SelectedDirectoryDao extends DatabaseAccessor<AppDatabase>
    with _$SelectedDirectoryDaoMixin {
  SelectedDirectoryDao(super.db);

  Future<List<SelectedDirectory>> getAllSelectedDirectories() =>
      select(selectedDirectories).get();

  Stream<List<SelectedDirectory>> watchAllSelectedDirectories() =>
      select(selectedDirectories).watch().distinct();

  Future<int> insertSelectedDirectory(SelectedDirectoriesCompanion companion) {
    return into(selectedDirectories).insert(
      companion,
      mode: InsertMode.insertOrIgnore,
      onConflict: DoNothing(),
    );
  }

  Future<int> deleteSelectedDirectory(String path) {
    return (delete(
      selectedDirectories,
    )..where((t) => t.rawPath.equals(path))).go();
  }
}

@DriftAccessor(tables: [ReadingHistories])
class ReadingHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingHistoryDaoMixin {
  ReadingHistoryDao(super.db);

  Future<void> recordReading(ReadingHistoriesCompanion companion) async {
    await into(readingHistories).insert(
      companion,
      onConflict: DoUpdate(
        (old) => ReadingHistoriesCompanion.custom(
          lastReadTime: Variable(companion.lastReadTime.value),
          title: Variable(companion.title.value),
          coverUrl: Variable(companion.coverUrl.value),
          chapterId: companion.chapterId.present
              ? Variable(companion.chapterId.value)
              : null,
          pageIndex: companion.pageIndex.present
              ? Variable(companion.pageIndex.value)
              : null,
        ),
        target: [readingHistories.comicId],
      ),
    );
  }

  Future<ReadingHistory?> getReadingHistoryByComicId(String comicId) {
    return (select(
      readingHistories,
    )..where((t) => t.comicId.equals(comicId))).getSingleOrNull();
  }

  Stream<List<ReadingHistory>> watchAllHistory() {
    return (select(
      readingHistories,
    )..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)])).watch();
  }

  Future<void> clearExpiredHistory() async {
    final limitDate = DateTime.now().subtract(const Duration(days: 365));
    await (delete(
      readingHistories,
    )..where((t) => t.lastReadTime.isSmallerThanValue(limitDate))).go();
  }
}

// 数据模型
class ComicWithChaptersAndTags {
  final Comic comic;
  final Set<Chapter> chapters;
  final Set<CategoryTag> tags;

  ComicWithChaptersAndTags({
    required this.comic,
    required this.chapters,
    required this.tags,
  });

  @override
  String toString() =>
      'ComicWithChaptersAndTags(comic: $comic, chapters: $chapters, tags: $tags)';
}
