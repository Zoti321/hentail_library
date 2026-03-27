import 'dart:io';

import 'package:hentai_library/data/services/comic/scanner/directory_scan_helper.dart';
import 'package:hentai_library/data/services/comic/v2/resource_types.dart';
import 'package:path/path.dart' as p;

/// 扫描器：递归收集路径并标注 ResourceType。
///
/// - 输出基础单元：({path,type})
/// - 目录：若满足纯图片漫画目录规则 -> type=dir 并停止向下递归
/// - 文件：按后缀映射 zip/cbz/epub/cbr/rar
class ResourceScanner {
  Stream<ResourceCandidate> scanRoots(
    Iterable<String> roots, {
    bool Function()? isCancelled,
  }) async* {
    for (final root in roots) {
      if (isCancelled?.call() == true) return;
      final path = root.trim();
      if (path.isEmpty) continue;

      final entityType = await FileSystemEntity.type(path, followLinks: false);
      if (entityType == FileSystemEntityType.notFound) continue;

      if (entityType == FileSystemEntityType.directory) {
        yield* _scanDirectory(
          Directory(path),
          isCancelled: isCancelled,
        );
        continue;
      }

      if (entityType == FileSystemEntityType.file) {
        final candidate = _candidateFromFilePath(path);
        if (candidate != null) yield candidate;
      }
    }
  }

  ResourceCandidate? _candidateFromFilePath(String path) {
    final fileName = p.basename(path);
    if (fileName.startsWith('.')) return null;
    final type = resourceTypeFromFilePath(path);
    if (type == null) return null;
    return (path: path, type: type);
  }

  Stream<ResourceCandidate> _scanDirectory(
    Directory dir, {
    bool Function()? isCancelled,
  }) async* {
    if (isCancelled?.call() == true) return;

    try {
      final top = await scanTopLevelForManga(dir);
      if (top.isManga) {
        yield (path: dir.path, type: ResourceType.dir);
        return;
      }

      await for (final entity in dir.list(
        recursive: false,
        followLinks: false,
      )) {
        if (isCancelled?.call() == true) return;

        if (entity is Directory) {
          yield* _scanDirectory(entity, isCancelled: isCancelled);
          continue;
        }

        if (entity is File) {
          final candidate = _candidateFromFilePath(entity.path);
          if (candidate != null) yield candidate;
        }
      }
    } catch (_) {
      // 扫描器阶段只做收集：IO 异常直接跳过该分支
      return;
    }
  }
}

