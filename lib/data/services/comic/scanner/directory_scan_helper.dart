import 'dart:io';

import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:path/path.dart' as p;

/// 顶层目录扫描结果（只扫描一层，不递归）。
class TopLevelDirectoryScanResult {
  final List<File> images;
  final List<Directory> subDirs;
  final bool isManga;

  TopLevelDirectoryScanResult({
    required this.images,
    required this.subDirs,
    required this.isManga,
  });
}

/// 扫描顶层目录：
/// - 只考虑顶层文件/子目录（`recursive:false`）
/// - 忽略以 `.` 开头的隐藏文件
/// - `isManga` 规则与现有实现保持一致：
///   至少有 1 张图片 && 顶层没有子目录 && 顶层不存在非图片文件
Future<TopLevelDirectoryScanResult> scanTopLevelForManga(Directory dir) async {
  final images = <File>[];
  final subDirs = <Directory>[];
  var hasInvalidFile = false;

  await for (final entity in dir.list(
    recursive: false,
    followLinks: false,
  )) {
    if (entity is Directory) {
      subDirs.add(entity);
      continue;
    }

    if (entity is File) {
      final fileName = p.basename(entity.path);
      if (fileName.startsWith('.')) continue; // 忽略隐藏文件

      final ext = p.extension(entity.path).toLowerCase();
      if (comicImageExtensions.contains(ext)) {
        images.add(entity);
      } else {
        hasInvalidFile = true;
      }
    }
  }

  final isManga = images.isNotEmpty && !hasInvalidFile && subDirs.isEmpty;
  return TopLevelDirectoryScanResult(
    images: images,
    subDirs: subDirs,
    isManga: isManga,
  );
}

/// 按“封面优先”规则排序图片文件：
/// - 文件名包含 `cover` 的排在前面
/// - 其余按路径稳定排序
List<File> orderedImageFilesForCover(Iterable<File> imageFiles) {
  final files = imageFiles.toList();
  files.sort((a, b) {
    final aName = p.basename(a.path).toLowerCase();
    final bName = p.basename(b.path).toLowerCase();

    if (aName.contains('cover') && !bName.contains('cover')) return -1;
    if (!aName.contains('cover') && bName.contains('cover')) return 1;
    return a.path.compareTo(b.path);
  });
  return files;
}

