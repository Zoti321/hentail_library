import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hentai_library/core/util/filename_natural_compare.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_exception.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/reader_image.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/utils/comic_read_image_mime.dart';
import 'package:path/path.dart' as p;

/// 压缩包访问器：用于 zip/cbz 漫画资源读取。
class ZipComicReadResourceAccessor implements ComicReadResourceAccessor {
  ZipComicReadResourceAccessor({
    required File archiveFile,
    required Set<String> imageExtensions,
  }) : _archiveFile = archiveFile,
       _imageExtensions = imageExtensions;

  final File _archiveFile;
  final Set<String> _imageExtensions;
  List<ArchiveFile>? _orderedImageEntries;
  static const String _prepareRequiredMessage = '先调用 prepare()';

  @override
  int get pageCount {
    final List<ArchiveFile> entries = _requirePreparedEntries();
    return entries.length;
  }

  @override
  Future<void> prepare() async {
    if (_orderedImageEntries != null) {
      return;
    }
    if (!await _archiveFile.exists()) {
      throw ComicReadResourceInvalidContentException(
        message: '文件不存在: ${_archiveFile.path}',
      );
    }
    final Uint8List raw = await _archiveFile.readAsBytes();
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(raw);
    } catch (err) {
      throw ComicReadResourceInvalidContentException(
        message: '无法解码 ZIP: ${_archiveFile.path}',
        cause: err,
      );
    }
    final List<ArchiveFile> imageEntries = <ArchiveFile>[];
    for (final ArchiveFile f in archive.files) {
      final String name = f.name.replaceAll(r'\', '/');
      if (!f.isFile || name.endsWith('/')) {
        continue;
      }
      final String ext = p.extension(name).toLowerCase();
      if (!_imageExtensions.contains(ext)) {
        continue;
      }
      imageEntries.add(f);
    }
    imageEntries.sort((ArchiveFile a, ArchiveFile b) {
      final String nameA = a.name.replaceAll(r'\', '/');
      final String nameB = b.name.replaceAll(r'\', '/');
      return compareFilenameNatural(p.basename(nameA), p.basename(nameB));
    });
    if (imageEntries.isEmpty) {
      throw ComicReadResourceInvalidContentException(
        message: '压缩包内无漫画图片: ${_archiveFile.path}',
      );
    }
    _orderedImageEntries = List<ArchiveFile>.unmodifiable(imageEntries);
  }

  @override
  Future<void> dispose() async {
    _orderedImageEntries = null;
  }

  @override
  Future<ReaderImage> getCoverImage() async {
    final List<ArchiveFile> entries = _requirePreparedEntries();
    for (final ArchiveFile f in entries) {
      final String name = f.name.replaceAll(r'\', '/');
      if (p.basenameWithoutExtension(name).toLowerCase() == 'cover') {
        return _bytesImageForEntry(f, name);
      }
    }
    return _bytesImageForEntry(entries.first, entries.first.name);
  }

  @override
  Future<ReaderImage> getPageImage(int pageIndex) async {
    final List<ArchiveFile> entries = _requirePreparedEntries();
    if (pageIndex < 0 || pageIndex >= entries.length) {
      throw ComicReadResourceInvalidContentException(
        message: '页索引越界: index=$pageIndex count=${entries.length}',
      );
    }
    final ArchiveFile f = entries[pageIndex];
    return _bytesImageForEntry(f, f.name);
  }

  List<ArchiveFile> _requirePreparedEntries() {
    final List<ArchiveFile>? entries = _orderedImageEntries;
    if (entries == null) {
      throw StateError(_prepareRequiredMessage);
    }
    return entries;
  }

  ReaderBytesImage _bytesImageForEntry(ArchiveFile f, String nameForMime) {
    final Object content = f.content;
    if (content is! List<int>) {
      throw ComicReadResourceInvalidContentException(
        message: '压缩项无内容: ${f.name}',
      );
    }
    final Uint8List bytes = Uint8List.fromList(content);
    final String? mime = inferComicImageMimeType(nameForMime);
    return ReaderBytesImage(bytes, mimeType: mime);
  }
}

