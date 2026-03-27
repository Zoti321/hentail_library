import 'dart:io';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/data/services/comic/scanner/comic_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:talker/talker.dart';

/// 封面修复所需的最小信息载体。
class CoverRepairCandidate {
  final String comicId;
  final String? coverUrl;
  final String? sourcePath;

  const CoverRepairCandidate({
    required this.comicId,
    required this.coverUrl,
    required this.sourcePath,
  });
}

/// 封面修复服务
///
/// 根据给定的最小信息（comicId/coverUrl/sourcePath），检查封面文件是否缺失并尝试基于 sourcePath 重新生成缓存。
///
/// 当前仅在 presentation/providers 中注入，供后续设置页或维护功能（如批量修复缺失封面）调用。
/// 若从 UI 触发，建议经 domain 层用例（如 RepairComicCoverUseCase）封装，入参使用 comicId 或领域实体。
class CoverRepairService {
  static const _repairableExtensions = {
    ...epubExtensions,
    ...comicArchiveExtensions,
  };

  final ComicScannerService _scannerService;
  final Talker _log;

  CoverRepairService({required ComicScannerService scannerService, Talker? log})
    : _scannerService = scannerService,
      _log = log ?? LogManager.instance;

  /// 针对单本漫画尝试修复封面缓存
  Future<void> repairSingle(CoverRepairCandidate candidate) async {
    final coverUrl = candidate.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) return;
    if (await File(coverUrl).exists()) return;

    final sourcePath = candidate.sourcePath;
    if (sourcePath == null || sourcePath.isEmpty) return;
    final ext = p.extension(sourcePath).toLowerCase();
    if (!_repairableExtensions.contains(ext)) return;
    if (!await File(sourcePath).exists()) return;

    _log.info(
      '[REPAIR][START] 开始修复封面，漫画ID=${candidate.comicId}，来源路径=$sourcePath',
    );

    try {
      await _scannerService.scanPath(sourcePath);
      _log.info(
        '[REPAIR][END] 修复封面成功，漫画ID=${candidate.comicId}',
      );
    } catch (e, st) {
      _log.handle(
        e,
        st,
        '[REPAIR][ERROR] 重新缓存漫画封面失败，漫画ID=${candidate.comicId}',
      );
      _log.info(
        '[REPAIR][END] 修复封面失败，漫画ID=${candidate.comicId}',
      );
    }
  }

  /// 针对一批漫画尝试批量修复封面缓存
  Future<void> repairBatch(Iterable<CoverRepairCandidate> candidates) async {
    for (final c in candidates) {
      await repairSingle(c);
    }
  }
}
