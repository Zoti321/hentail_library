import 'dart:async';
import 'package:drift/drift.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/services/comic/comic.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/mappers.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;

// 对外统一接口：聚合查询 + 委托同步到 ComicSyncService
class ComicRepositoryImpl extends ComicRepository {
  final ComicDao _comicDao;
  final CategoryTagDao _categoryTagDao;
  final ComicSyncService _syncService;
  final ComicFileCacheService _cacheService;

  ComicRepositoryImpl(
    this._comicDao,
    this._categoryTagDao,
    this._syncService,
    this._cacheService,
  );

  @override
  Stream<List<entity.Comic>> watchComicAggregate() {
    return _comicDao.watchComicWithChaptersAndTags().asyncMap((
      comicList,
    ) async {
      return comicList.values.map((e) => e.toEntity()).toList();
    });
  }

  @override
  Future<List<entity.Comic>> getComicAggregate() async {
    final comicList = await _comicDao.getComicWithChaptersAndTags();
    return comicList.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<entity.Comic?> findById(String comicId) async {
    final entry =
        await _comicDao.getComicWithChaptersAndTagsById(comicId);
    return entry?.toEntity();
  }

  @override
  Future<void> ingestComicResources(
    List<String> rootDirs, {
    bool Function()? isCancelled,
  }) async {
    await _syncService.runSync(rootDirs, isCancelled: isCancelled);
  }

  @override
  Future<void> updateComicMetaData(
    String comicId,
    entity.ComicMetadataForm data,
  ) async {
    try {
      // 1. 更新漫画元数据
      await _comicDao.updateComicInfo(
        comicId,
        title: data.title,
        description: data.description,
        isR18: data.isR18,
      );

      // 2. 更新漫画关联的标签
      // 对分类标签进行更新 (覆写模式)
      final tags = data.tags;
      final companions = tags
          .map(
            (t) => CategoryTagsCompanion.insert(
              name: t.name,
              type: Value(t.type),
              isR18: Value(t.isR18),
            ),
          )
          .toList();

      await _categoryTagDao.updateComicTags(comicId, companions);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[COMIC_REPO] 更新漫画元数据失败，comicId=$comicId',
      );
      throw AppException('更新漫画元数据失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> archiveChaptersToComic(entity.ComicArchiveForm form) async {
    final comicId = form.comicId;
    final chapterIds = form.chapterIds;
    LogManager.instance.info(
      '[ARCHIVE][START] 开始归档操作，目标漫画ID=$comicId，本次要归档的章节数=${chapterIds.length}',
    );

    try {
      // 1. 将对应章节指向的漫画更新为目标漫画
      for (var chapter in chapterIds) {
        await _comicDao.updateChapterComic(chapter, comicId);
      }

      // 2. 找出不再拥有任何章节的「空壳」漫画（即被合并掉的来源漫画），删除它们
      final aggregate = await _comicDao.getComicWithChaptersAndTags();
      final emptyComicIds = aggregate.entries
          .where((e) => e.key != comicId && e.value.chapters.isEmpty)
          .map((e) => e.key)
          .toList();
      for (final id in emptyComicIds) {
        await _comicDao.deleteComic(id);
        await _cacheService.clearComicCache(id);
      }
      LogManager.instance.info(
        '[ARCHIVE][END] 归档完成，目标漫画ID=$comicId，被删除的空壳漫画数量=${emptyComicIds.length}',
      );
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[ARCHIVE][ERROR] 归档漫画章节失败，漫画ID=$comicId',
      );
      throw AppException('归档漫画章节失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> incrementReadCount(String comicId) async {
    try {
      await _comicDao.incrementViews(comicId);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[COMIC_REPO] 增加阅读次数失败，comicId=$comicId',
      );
      throw AppException('增加阅读次数失败', cause: e, stackTrace: st);
    }
  }
}
