import 'dart:io';

import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:path/path.dart' as p;

/// 按 [ResourceType] 从磁盘路径解析漫画封面与正文资源。
///
/// 当前仅实现 [ResourceType.dir]；其余类型方法体会抛出 [UnsupportedError]。
class ComicResourceGettingService {
  /// 返回目录漫画封面文件：优先 basename（不含扩展名）不区分大小写为 `cover` 的图片，否则为按名排序后的第一张。
  Future<File> getComicCover(String path, ResourceType type) async {
    await _validatePathMatchesType(path, type);
    return switch (type) {
      ResourceType.dir => _getDirCover(Directory(path)),
      ResourceType.zip ||
      ResourceType.cbz ||
      ResourceType.epub ||
      ResourceType.cbr ||
      ResourceType.rar =>
        throw UnsupportedError('getComicCover 尚未支持 ResourceType.$type'),
    };
  }

  /// 返回目录漫画正文图片列表（非递归、按 basename 排序）。
  Future<List<File>> getComicContent(String path, ResourceType type) async {
    await _validatePathMatchesType(path, type);
    return switch (type) {
      ResourceType.dir => _listDirComicImageFiles(Directory(path)),
      ResourceType.zip ||
      ResourceType.cbz ||
      ResourceType.epub ||
      ResourceType.cbr ||
      ResourceType.rar =>
        throw UnsupportedError('getComicContent 尚未支持 ResourceType.$type'),
    };
  }

  Future<void> _validatePathMatchesType(String rawPath, ResourceType type) async {
    final path = rawPath.trim();
    if (path.isEmpty) {
      throw ArgumentError('path 不能为空');
    }

    final entityType = await FileSystemEntity.type(path, followLinks: false);
    if (entityType == FileSystemEntityType.notFound) {
      throw ArgumentError('路径不存在: $path');
    }

    final inferred = _inferResourceType(path, entityType);
    if (inferred == null) {
      throw ArgumentError('路径不是有效的漫画资源（扩展名无法识别）: $path');
    }
    if (inferred != type) {
      throw ArgumentError(
        'path 与 ResourceType 不一致: 路径推断为 $inferred，入参为 $type',
      );
    }
  }

  static ResourceType? _inferResourceType(String path, FileSystemEntityType entityType) {
    if (entityType == FileSystemEntityType.directory) {
      return ResourceType.dir;
    }
    if (entityType == FileSystemEntityType.file) {
      return resourceTypeFromFilePath(path);
    }
    return null;
  }

  Future<List<File>> _listDirComicImageFiles(Directory dir) async {
    if (!await dir.exists()) {
      throw ArgumentError('目录不存在: ${dir.path}');
    }

    final entities = await dir
        .list(recursive: false, followLinks: false)
        .toList();

    final imageFiles = entities.whereType<File>().where((file) {
      final ext = p.extension(file.path).toLowerCase();
      return ComicFileTypes.comicImageExtensions.contains(ext);
    }).toList();

    imageFiles.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return imageFiles;
  }

  Future<File> _getDirCover(Directory dir) async {
    final files = await _listDirComicImageFiles(dir);
    if (files.isEmpty) {
      throw StateError('目录内无漫画图片: ${dir.path}');
    }

    for (final f in files) {
      if (p.basenameWithoutExtension(f.path).toLowerCase() == 'cover') {
        return f;
      }
    }
    return files.first;
  }
}
