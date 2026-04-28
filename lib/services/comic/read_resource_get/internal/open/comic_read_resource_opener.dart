import 'dart:io';

import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_exception.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/open/comic_read_resource_accessor_factory.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/utils/comic_read_path_normalizer.dart';

/// 打开器：负责路径/类型校验，编排 accessor prepare 生命周期。
class ComicReadResourceOpener {
  ComicReadResourceOpener({
    Set<String>? imageExtensions,
    ComicReadPathNormalizer? pathNormalizer,
    ComicReadResourceAccessorFactory? accessorFactory,
  })
    : _pathNormalizer = pathNormalizer ?? const ComicReadPathNormalizer(),
      _accessorFactory =
          accessorFactory ??
          ComicReadResourceAccessorFactory(
            imageExtensions:
                imageExtensions ??
                Set<String>.from(ComicFileTypes.comicImageExtensions),
          );

  final ComicReadPathNormalizer _pathNormalizer;
  final ComicReadResourceAccessorFactory _accessorFactory;
  static const String _pathEmptyDetail = 'path 为空';
  static const String _expectDirectoryDetail = '期望目录';
  static const String _expectFileDetail = '期望文件';

  Future<ComicReadResourceAccessor> open({
    required String path,
    required ResourceType type,
  }) async {
    final String normalized = _pathNormalizer.normalizePath(path);
    if (normalized.isEmpty) {
      throw _buildKindMismatch(path: path, type: type, detail: _pathEmptyDetail);
    }
    final FileSystemEntityType entityType = await FileSystemEntity.type(
      normalized,
      followLinks: false,
    );
    if (entityType == FileSystemEntityType.notFound) {
      throw ComicReadResourceNotFoundException(path: normalized);
    }
    _ensureEntityMatchesType(normalized, entityType, type);
    final ComicReadResourceAccessor accessor = _accessorFactory.createAccessor(
      normalizedPath: normalized,
      type: type,
    );
    await accessor.prepare();
    return accessor;
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
        throw _buildKindMismatch(
          path: normalizedPath,
          type: type,
          detail: _expectDirectoryDetail,
        );
      }
      return;
    }
    if (entityType != FileSystemEntityType.file) {
      throw _buildKindMismatch(
        path: normalizedPath,
        type: type,
        detail: _expectFileDetail,
      );
    }
    final ResourceType? inferred = ResourceType.fromFilePath(normalizedPath);
    if (inferred != type) {
      throw ComicReadResourceKindMismatchException(
        path: normalizedPath,
        expectedType: type,
        detail: '扩展名推断为 ${inferred?.name ?? "未知"}',
      );
    }
  }

  ComicReadResourceKindMismatchException _buildKindMismatch({
    required String path,
    required ResourceType type,
    required String detail,
  }) {
    return ComicReadResourceKindMismatchException(
      path: path,
      expectedType: type,
      detail: detail,
    );
  }
}

