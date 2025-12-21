import 'dart:io';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/services/comic/scanner/comic_scanner.dart';
import 'package:path/path.dart' as p;

/// 封面修复服务
///
/// 根据聚合后的漫画记录，检查封面文件是否缺失并尝试基于章节的 sourcePath 重新生成缓存。
///
/// 当前仅在 presentation/providers 中注入，供后续设置页或维护功能（如批量修复缺失封面）调用。
/// 若从 UI 触发，建议经 domain 层用例（如 RepairComicCoverUseCase）封装，入参使用 comicId 或领域实体。
class CoverRepairService {
  final ComicScannerService _scannerService;

  CoverRepairService({required ComicScannerService scannerService})
    : _scannerService = scannerService;

  /// 针对单本漫画尝试修复封面缓存
  Future<void> repairSingle(ComicWithChaptersAndTags entry) async {
    final coverUrl = entry.comic.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) return;
    if (await File(coverUrl).exists()) return;

    final firstChapter = entry.chapters.isEmpty ? null : entry.chapters.first;
    if (firstChapter == null) return;

    final sourcePath = firstChapter.sourcePath;
    if (sourcePath == null || sourcePath.isEmpty) return;
    if (p.extension(sourcePath).toLowerCase() != '.epub') return;
    if (!await File(sourcePath).exists()) return;

    LogManager.instance.info(
      '[REPAIR][START] 开始修复封面，漫画ID=${entry.comic.comicId}，来源路径=$sourcePath',
    );

    try {
      await _scannerService.scanPath(sourcePath);
      LogManager.instance.info(
        '[REPAIR][END] 修复封面成功，漫画ID=${entry.comic.comicId}',
      );
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[REPAIR][ERROR] 重新缓存漫画封面失败，漫画ID=${entry.comic.comicId}',
      );
      LogManager.instance.info(
        '[REPAIR][END] 修复封面失败，漫画ID=${entry.comic.comicId}',
      );
    }
  }

  /// 针对一批漫画尝试批量修复封面缓存
  Future<void> repairBatch(Iterable<ComicWithChaptersAndTags> entries) async {
    for (final entry in entries) {
      await repairSingle(entry);
    }
  }
}
