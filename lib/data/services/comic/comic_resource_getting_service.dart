import 'dart:io';

import 'package:hentai_library/data/services/comic/comic_resource_content_handler.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/util/enums.dart';

/// 按 [ResourceType] 从磁盘路径解析漫画封面与正文资源。
///
/// 具体行为由 [ComicResourceContentHandler] 注册表决定（与 [ResourceParser] 链式策略对齐）。
class ComicResourceGettingService {
  ComicResourceGettingService({List<ComicResourceContentHandler>? handlers})
    : _handlers = _indexByType(
        handlers ?? defaultComicResourceContentHandlers(),
      );

  final Map<ResourceType, ComicResourceContentHandler> _handlers;

  static Map<ResourceType, ComicResourceContentHandler> _indexByType(
    List<ComicResourceContentHandler> handlers,
  ) {
    final m = <ResourceType, ComicResourceContentHandler>{};
    for (final h in handlers) {
      m[h.type] = h;
    }
    if (m.length != ResourceType.values.length) {
      throw ArgumentError(
        'handlers 必须为每个 ResourceType 提供恰好一个处理器（当前 ${m.length}，'
        '期望 ${ResourceType.values.length}）',
      );
    }
    return Map<ResourceType, ComicResourceContentHandler>.unmodifiable(m);
  }

  /// 返回漫画封面文件（语义见各 [ComicResourceContentHandler]）。
  Future<File> getComicCover(String path, ResourceType type) async {
    await _validatePathMatchesType(path, type);
    return _handlers[type]!.getCover(path.trim());
  }

  /// 返回正文图片列表（语义见各 [ComicResourceContentHandler]）。
  Future<List<File>> getComicContent(String path, ResourceType type) async {
    await _validatePathMatchesType(path, type);
    return _handlers[type]!.getContent(path.trim());
  }

  Future<void> _validatePathMatchesType(
    String rawPath,
    ResourceType type,
  ) async {
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
      throw ArgumentError('path 与 ResourceType 不一致: 路径推断为 $inferred，入参为 $type');
    }
  }

  static ResourceType? _inferResourceType(
    String path,
    FileSystemEntityType entityType,
  ) {
    if (entityType == FileSystemEntityType.directory) {
      return ResourceType.dir;
    }
    if (entityType == FileSystemEntityType.file) {
      return resourceTypeFromFilePath(path);
    }
    return null;
  }
}
