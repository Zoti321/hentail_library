import 'dart:io';
import 'dart:typed_data';

import 'package:epub_image_extractor/epub_image_extractor.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/comic_read_resource_exception.dart';
import 'package:hentai_library/services/comic/read_resource_get/core/reader_image.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/utils/comic_read_image_mime.dart';
import 'package:path/path.dart' as p;

/// EPUB 访问器：按书内阅读顺序提取图片。
class EpubComicReadResourceAccessor implements ComicReadResourceAccessor {
  EpubComicReadResourceAccessor({required File epubFile, EpubParser? parser})
    : _epubFile = epubFile,
      _parser = parser ?? EpubParser();

  final File _epubFile;
  final EpubParser _parser;
  EpubExtractionResult? _result;
  static const String _prepareRequiredMessage = '先调用 prepare()';

  @override
  int get pageCount {
    final EpubExtractionResult r = _requirePreparedResult();
    return r.images.length;
  }

  @override
  Future<void> prepare() async {
    if (_result != null) {
      return;
    }
    if (!await _epubFile.exists()) {
      throw ComicReadResourceInvalidContentException(
        message: '文件不存在: ${_epubFile.path}',
      );
    }
    try {
      _result = await _parser.extract(_epubFile);
    } catch (err) {
      throw ComicReadResourceInvalidContentException(
        message: '无法解析 EPUB: ${_epubFile.path}',
        cause: err,
      );
    }
    if (_result!.images.isEmpty) {
      throw ComicReadResourceInvalidContentException(
        message: 'EPUB 内无图片: ${_epubFile.path}',
      );
    }
  }

  @override
  Future<void> dispose() async {
    _result = null;
  }

  @override
  Future<ReaderImage> getCoverImage() async {
    final EpubExtractionResult result = _requirePreparedResult();
    for (final ImageInfo info in result.images) {
      if (p.basename(info.path).toLowerCase().contains('cover')) {
        return _bytesForImage(result, info);
      }
    }
    return _bytesForImage(result, result.images.first);
  }

  @override
  Future<ReaderImage> getPageImage(int pageIndex) async {
    final EpubExtractionResult result = _requirePreparedResult();
    if (pageIndex < 0 || pageIndex >= result.images.length) {
      throw ComicReadResourceInvalidContentException(
        message: '页索引越界: index=$pageIndex count=${result.images.length}',
      );
    }
    return _bytesForImage(result, result.images[pageIndex]);
  }

  EpubExtractionResult _requirePreparedResult() {
    final EpubExtractionResult? r = _result;
    if (r == null) {
      throw StateError(_prepareRequiredMessage);
    }
    return r;
  }

  ReaderBytesImage _bytesForImage(EpubExtractionResult result, ImageInfo info) {
    final Uint8List? data = _parser.getImageData(result, info);
    if (data == null) {
      throw ComicReadResourceInvalidContentException(
        message: '图片不存在: ${info.path}',
      );
    }
    final String? mime = info.mediaType.startsWith('image/')
        ? info.mediaType
        : inferComicImageMimeType(info.path);
    return ReaderBytesImage(data, mimeType: mime);
  }
}

