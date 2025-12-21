import 'dart:io';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/models/models.dart';
import 'package:path/path.dart' as p;

class DirectoryParseService {
  static const imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};

  bool isImage(String path) {
    return imageExtensions.contains(p.extension(path).toLowerCase());
  }

  Stream<Directory> analyzeDirectory(Directory dir) async* {
    try {
      final result = await _checkDirectoryContent(dir);

      if (result.isManga) {
        LogManager.instance.info('🎯 找到漫画目录: ${dir.path}');
        yield dir;
      } else {
        for (final subDir in result.subDirs) {
          yield* analyzeDirectory(subDir);
        }
      }
    } catch (e, st) {
      LogManager.instance.handle(e, st, '目录扫描错误: ${dir.path}');
    }
  }

  Future<DirectoryScanResult> _checkDirectoryContent(Directory dir) async {
    List<File> images = [];
    List<Directory> subDirs = [];
    bool hasInvalidFile = false;

    try {
      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is Directory) {
          subDirs.add(entity);
        } else if (entity is File) {
          final fileName = p.basename(entity.path);
          if (fileName.startsWith('.')) continue; // 忽略隐藏文件
          if (isImage(entity.path)) {
            images.add(entity);
          } else {
            hasInvalidFile = true;
          }
        }
      }
    } catch (e, st) {
      LogManager.instance.warning('IO 访问 Denied/Error: ${dir.path}', e, st);
    }

    bool isManga = images.isNotEmpty && !hasInvalidFile && subDirs.isEmpty;
    return DirectoryScanResult(
      images: images,
      subDirs: subDirs,
      isManga: isManga,
    );
  }
}
