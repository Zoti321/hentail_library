import 'dart:io';

import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_exception.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/dir_comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/epub_comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/zip_comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/scan/resource_types.dart';
import 'package:hentai_library/domain/util/enums.dart';

/// 按 [ResourceType] 打开漫画资源并完成 [ComicReadResourceAccessor.prepare]。
class ComicReadResourceOpener {
  ComicReadResourceOpener({Set<String>? imageExtensions})
    : _imageExtensions = imageExtensions ?? Set<String>.from(ComicFileTypes.comicImageExtensions);

  final Set<String> _imageExtensions;

  /// 校验路径与类型后创建访问器；返回前已 [ComicReadResourceAccessor.prepare]。
  Future<ComicReadResourceAccessor> open({
    required String path,
    required ResourceType type,
  }) async {
    final String normalized = _normalizePath(path);
    if (normalized.isEmpty) {
      throw ComicReadResourceKindMismatchException(
        path: path,
        expectedType: type,
        detail: 'path 为空',
      );
    }
    final FileSystemEntityType entityType =
        await FileSystemEntity.type(normalized, followLinks: false);
    if (entityType == FileSystemEntityType.notFound) {
      throw ComicReadResourceNotFoundException(path: normalized);
    }
    _ensureEntityMatchesType(normalized, entityType, type);
    final ComicReadResourceAccessor accessor = _createAccessor(
      normalizedPath: normalized,
      type: type,
    );
    await accessor.prepare();
    return accessor;
  }

  ComicReadResourceAccessor _createAccessor({
    required String normalizedPath,
    required ResourceType type,
  }) {
    switch (type) {
      case ResourceType.dir:
        return DirComicReadResourceAccessor(
          directory: Directory(normalizedPath),
          imageExtensions: _imageExtensions,
        );
      case ResourceType.zip:
      case ResourceType.cbz:
        return ZipComicReadResourceAccessor(
          archiveFile: File(normalizedPath),
          imageExtensions: _imageExtensions,
        );
      case ResourceType.epub:
        return EpubComicReadResourceAccessor(epubFile: File(normalizedPath));
      case ResourceType.cbr:
      case ResourceType.rar:
        throw ComicReadResourceUnsupportedTypeException(type: type);
    }
  }

  void _ensureEntityMatchesType(
    String normalizedPath,
    FileSystemEntityType entityType,
    ResourceType type,
  ) {
    if (type == ResourceType.cbr || type == ResourceType.rar) {
      throw ComicReadResourceUnsupportedTypeException(type: type);
    }
    if (type == ResourceType.dir) {
      if (entityType != FileSystemEntityType.directory) {
        throw ComicReadResourceKindMismatchException(
          path: normalizedPath,
          expectedType: type,
          detail: '期望目录',
        );
      }
      return;
    }
    if (entityType != FileSystemEntityType.file) {
      throw ComicReadResourceKindMismatchException(
        path: normalizedPath,
        expectedType: type,
        detail: '期望文件',
      );
    }
    final ResourceType? inferred = resourceTypeFromFilePath(normalizedPath);
    if (inferred != type) {
      throw ComicReadResourceKindMismatchException(
        path: normalizedPath,
        expectedType: type,
        detail: '扩展名推断为 ${inferred?.name ?? "未知"}',
      );
    }
  }

  String _normalizePath(String rawPath) {
    return rawPath.trim().replaceAll('\\', '/');
  }
}
