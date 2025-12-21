import 'dart:io';
import 'package:drift/drift.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/models/scanned_comic_model.dart';
import 'package:hentai_library/data/services/comic/comic_file_cache.dart';
import 'package:hentai_library/data/services/comic/parser/directory_parse.dart';
import 'package:hentai_library/data/services/comic/scanner/comic_scanner.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:path/path.dart' as p;
import 'package:talker/talker.dart';

/// 漫画资源同步服务：负责目录校验、扫描、差异计算、应用差异与缓存清理。
/// 仅被 [ComicRepositoryImpl] 的 [ComicRepository.ingestComicResources] 调用。
class ComicSyncService {
  final ComicDao _comicDao;
  final DirectoryParseService _folderParseService;
  final ComicScannerService _scannerService;
  final ComicFileCacheService _cacheService;

  ComicSyncService(
    this._comicDao,
    this._folderParseService,
    this._scannerService,
    this._cacheService,
  );

  /// 执行同步：校验目录 → 扫描 → 计算差异 → 写入/删除 DB 与缓存。
  Future<void> runSync(
    List<String> rootDirs, {
    bool Function()? isCancelled,
  }) async {
    final syncId = _generateSyncId();
    LogManager.instance.info(
      '[SYNC][START][syncId=$syncId] 本次同步的根目录数量=${rootDirs.length}',
    );
    final stopwatch = Stopwatch()..start();

    final dirs = rootDirs.map((p) => Directory(p)).toList();

    await _validateRootDirs(dirs);

    if (isCancelled?.call() == true) {
      LogManager.instance.info(
        '[SYNC][CANCEL][syncId=$syncId] 在开始扫描前被取消',
      );
      return;
    }

    final (scanComics, scanChapters) = await _getComicsFromScanDirectory(
      dirs,
      isCancelled: isCancelled,
      syncId: syncId,
    );

    final diff = await _calculateDiff(scanComics, scanChapters);

    _logDiff(diff, syncId);

    await _applyDiff(diff, syncId);

    stopwatch.stop();
    LogManager.instance.info(
      '[SYNC][END][syncId=$syncId] 本次同步耗时=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  String _generateSyncId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _validateRootDirs(List<Directory> dirs) async {
    await Future.wait(
      dirs.map((dir) async {
        if (!await dir.exists()) {
          throw ValidationException("无效的目录路径: ${dir.path}");
        }
      }),
    );
  }

  Future<_ComicSyncDiff> _calculateDiff(
    Map<String, ComicsCompanion> scanComics,
    Map<String, ChaptersCompanion> scanChapters,
  ) async {
    final localComics = (await _comicDao.getAllComics())
        .map((e) => e.comicId)
        .toList();
    final localChapterRows = await _comicDao.getAllChapters();
    final localChapters = localChapterRows.map((e) => e.chapterId).toList();

    final comicsToInsert = scanComics.keys
        .where((s) => !localComics.contains(s))
        .toList();
    final comicsToDelete = localComics
        .where((s) => !scanComics.keys.contains(s))
        .toList();

    final chaptersToInsert = scanChapters.keys
        .where((s) => !localChapters.contains(s))
        .toList();
    final chaptersToDelete = localChapters
        .where((s) => !scanChapters.keys.contains(s))
        .toList();

    return _ComicSyncDiff(
      scanComics: scanComics,
      scanChapters: scanChapters,
      comicsToInsert: comicsToInsert,
      comicsToDelete: comicsToDelete,
      chaptersToInsert: chaptersToInsert,
      chaptersToDelete: chaptersToDelete,
    );
  }

  void _logDiff(_ComicSyncDiff diff, String syncId) {
    LogManager.instance.log(
      '[SYNC][DIFF][syncId=$syncId] '
      '待新增漫画=${diff.comicsToInsert.length} 本，'
      '待删除漫画=${diff.comicsToDelete.length} 本，'
      '待新增章节=${diff.chaptersToInsert.length} 个，'
      '待删除章节=${diff.chaptersToDelete.length} 个',
      logLevel: LogLevel.info,
    );
  }

  Future<void> _applyDiff(_ComicSyncDiff diff, String syncId) async {
    try {
      final comicCompanionToInsert = diff.comicsToInsert
          .map((id) => diff.scanComics[id])
          .whereType<ComicsCompanion>()
          .toList();
      final chapterCompanionToInsert = diff.chaptersToInsert
          .map((id) => diff.scanChapters[id])
          .whereType<ChaptersCompanion>()
          .toList();

      LogManager.instance.info(
        '[SYNC][APPLY][syncId=$syncId] '
        '即将写入漫画=${comicCompanionToInsert.length} 本，'
        '写入章节=${chapterCompanionToInsert.length} 个，'
        '删除漫画=${diff.comicsToDelete.length} 本，'
        '删除章节=${diff.chaptersToDelete.length} 个',
      );

      await _comicDao.batchInsertComics(comicCompanionToInsert);
      await _comicDao.batchInsertChapters(chapterCompanionToInsert);

      await _comicDao.batchDeleteComics(diff.comicsToDelete);
      await _comicDao.batchDeleteChapters(diff.chaptersToDelete);
      for (final comicId in diff.comicsToDelete) {
        await _cacheService.clearComicCache(comicId);
      }

      LogManager.instance.debug(
        '[SYNC][APPLY][syncId=$syncId] '
        '数据库操作成功：实际写入漫画=${comicCompanionToInsert.length} 本，'
        '实际删除漫画=${diff.comicsToDelete.length} 本',
      );
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[SYNC][ERROR][syncId=$syncId] 增量同步到数据库时发生异常',
      );
      throw SyncException(
        '同步资源失败',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Future<(Map<String, ComicsCompanion>, Map<String, ChaptersCompanion>)>
      _getComicsFromScanDirectory(
    List<Directory> rootDirs, {
    bool Function()? isCancelled,
    required String syncId,
  }) async {
    final comicsMap = <String, ComicsCompanion>{};
    final chaptersMap = <String, ChaptersCompanion>{};
    final paths = await _collectComicPaths(
      rootDirs,
      isCancelled: isCancelled,
      syncId: syncId,
    );

    var scannedOk = 0;
    var scannedFailed = 0;

    for (final path in paths) {
      if (isCancelled?.call() == true) {
        LogManager.instance.info(
          '[SYNC][CANCEL][syncId=$syncId] 在扫描路径阶段被取消',
        );
        break;
      }
      final model = await _scannerService.scanPath(path);
      if (model != null) {
        scannedOk++;
        final (comic, chapter) = _scannedModelToCompanions(model);
        comicsMap[model.comicId] = comic;
        chaptersMap[model.chapterId] = chapter;
        LogManager.instance.debug(
          '[SYNC][SCAN_TO_DTO][syncId=$syncId] '
          '解析成功 path=$path comicId=${model.comicId} title=${model.title}',
        );
      } else {
        scannedFailed++;
        LogManager.instance.debug(
          '[SYNC][SCAN_TO_DTO][syncId=$syncId] '
          '跳过 path=$path 原因=不符合漫画目录/EPUB 规则或解析失败',
        );
      }
    }

    LogManager.instance.info(
      '[SYNC][SCAN_TO_DTO][syncId=$syncId] '
      '本次共扫描路径=${paths.length} 个，成功=$scannedOk 个，失败/跳过=$scannedFailed 个',
    );

    return (comicsMap, chaptersMap);
  }

  /// 将扫描 DTO 转为 Drift companions，由本服务集中处理持久化形态。
  (ComicsCompanion, ChaptersCompanion) _scannedModelToCompanions(
    ScannedComicModel m,
  ) {
    final comic = ComicsCompanion.insert(
      comicId: m.comicId,
      title: m.title,
      description: Value.absentIfNull(m.description),
      coverUrl: Value.absentIfNull(m.coverUrl),
      firstPublishedAt: Value.absentIfNull(m.firstPublishedAt),
      lastUpdatedAt: Value.absentIfNull(m.lastUpdatedAt),
    );
    final chapter = ChaptersCompanion.insert(
      chapterId: m.chapterId,
      comicId: m.comicId,
      title: Value.absentIfNull(m.chapterTitle),
      coverUrl: Value.absentIfNull(m.chapterCoverUrl),
      pageCount: Value.absentIfNull(m.pageCount),
      imageDir: Value(m.imageDir),
      number: Value(m.chapterNumber),
      sourcePath: Value.absentIfNull(m.sourcePath),
    );
    return (comic, chapter);
  }

  Future<List<String>> _collectComicPaths(
    List<Directory> rootDirs, {
    bool Function()? isCancelled,
    required String syncId,
  }) async {
    final paths = <String>[];

    for (final root in rootDirs) {
      if (isCancelled?.call() == true) {
        break;
      }
      await for (final comicDir in _folderParseService.analyzeDirectory(root)) {
        if (isCancelled?.call() == true) {
          break;
        }
        paths.add(comicDir.path);
      }
      for (final epubPath in await _findEpubFiles(root)) {
        paths.add(epubPath);
      }
    }

    LogManager.instance.info(
      '[SYNC][SCAN_COLLECT_PATHS][syncId=$syncId] '
      '已收集候选漫画路径=${paths.length} 个，来自根目录=${rootDirs.length} 个',
    );

    return paths;
  }

  Future<List<String>> _findEpubFiles(Directory dir) async {
    final epubs = <String>[];
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File &&
            p.extension(entity.path).toLowerCase() == '.epub') {
          epubs.add(entity.path);
        }
      }
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[SYNC][ERROR] 查找 EPUB 文件失败，目录=${dir.path}',
      );
    }
    return epubs;
  }
}

/// 漫画资源同步的差异描述
class _ComicSyncDiff {
  final Map<String, ComicsCompanion> scanComics;
  final Map<String, ChaptersCompanion> scanChapters;
  final List<String> comicsToInsert;
  final List<String> comicsToDelete;
  final List<String> chaptersToInsert;
  final List<String> chaptersToDelete;

  _ComicSyncDiff({
    required this.scanComics,
    required this.scanChapters,
    required this.comicsToInsert,
    required this.comicsToDelete,
    required this.chaptersToInsert,
    required this.chaptersToDelete,
  });
}
