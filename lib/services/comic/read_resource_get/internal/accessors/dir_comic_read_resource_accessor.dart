import 'dart:io';

import 'package:hentai_library/core/util/filename_natural_compare.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_exception.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/reader_image.dart';
import 'package:path/path.dart' as p;

/// 目录访问器：用于读取纯图片目录漫画资源。
class DirComicReadResourceAccessor implements ComicReadResourceAccessor {
  DirComicReadResourceAccessor({
    required Directory directory,
    required Set<String> imageExtensions,
  }) : _directory = directory,
       _imageExtensions = imageExtensions;

  final Directory _directory;
  final Set<String> _imageExtensions;
  List<File>? _orderedFiles;
  static const String _prepareRequiredMessage = '先调用 prepare()';

  @override
  int get pageCount {
    final List<File> files = _requirePreparedFiles();
    return files.length;
  }

  @override
  Future<void> prepare() async {
    if (_orderedFiles != null) {
      return;
    }
    await _loadOrderedFiles();
  }

  @override
  Future<void> dispose() async {
    _orderedFiles = null;
  }

  @override
  Future<ReaderImage> getCoverImage() async {
    final List<File> files = _requirePreparedFiles();
    if (files.isEmpty) {
      throw ComicReadResourceInvalidContentException(
        message: '目录内无漫画图片: ${_directory.path}',
      );
    }
    for (final File f in files) {
      if (p.basenameWithoutExtension(f.path).toLowerCase() == 'cover') {
        return ReaderFileImage(f);
      }
    }
    return ReaderFileImage(files.first);
  }

  @override
  Future<ReaderImage> getPageImage(int pageIndex) async {
    final List<File> files = _requirePreparedFiles();
    if (pageIndex < 0 || pageIndex >= files.length) {
      throw ComicReadResourceInvalidContentException(
        message: '页索引越界: index=$pageIndex count=${files.length}',
      );
    }
    return ReaderFileImage(files[pageIndex]);
  }

  List<File> _requirePreparedFiles() {
    final List<File>? files = _orderedFiles;
    if (files == null) {
      throw StateError(_prepareRequiredMessage);
    }
    return files;
  }

  Future<void> _loadOrderedFiles() async {
    if (!await _directory.exists()) {
      throw ComicReadResourceInvalidContentException(
        message: '目录不存在: ${_directory.path}',
      );
    }
    final List<FileSystemEntity> entities = await _directory
        .list(recursive: false, followLinks: false)
        .toList();
    final List<File> imageFiles = entities.whereType<File>().where((File file) {
      final String ext = p.extension(file.path).toLowerCase();
      return _imageExtensions.contains(ext);
    }).toList();
    imageFiles.sort((File a, File b) {
      return compareFilenameNatural(p.basename(a.path), p.basename(b.path));
    });
    _orderedFiles = List<File>.unmodifiable(imageFiles);
  }
}

