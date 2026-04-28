import 'dart:io';

import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_exception.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/accessors/dir_comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/accessors/epub_comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/accessors/zip_comic_read_resource_accessor.dart';

/// 访问器工厂：根据资源类型分发具体 accessor 实现。
class ComicReadResourceAccessorFactory {
  ComicReadResourceAccessorFactory({required Set<String> imageExtensions})
    : _imageExtensions = imageExtensions;

  final Set<String> _imageExtensions;

  ComicReadResourceAccessor createAccessor({
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
}

