import 'dart:typed_data';

import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/clipboard_image_port.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';

typedef PageImagePngEncoder = Future<Uint8List> Function(Uint8List imageBytes);

/// Copy a reader page to the clipboard (load → encode PNG → write).
///
/// PNG encoding is injected; the engine-backed default lives in data adapters.
class CopyPageImageService {
  CopyPageImageService({
    required this._pageSource,
    required this._clipboardImage,
    required this._encodePng,
  });

  final ComicPageSourcePort _pageSource;
  final ClipboardImagePort _clipboardImage;
  final PageImagePngEncoder _encodePng;

  Future<void> execute({
    required ReaderComicRef comic,
    required int archivePageIndex,
  }) async {
    final Uint8List? sourceBytes;
    try {
      sourceBytes = await _pageSource.loadPageBytes(
        comicId: comic.comicId,
        pageIndex: archivePageIndex,
      );
    } on Object catch (error, stackTrace) {
      throw CopyPageImageException.loadFailed(
        archivePageIndex: archivePageIndex,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (sourceBytes == null || sourceBytes.isEmpty) {
      throw CopyPageImageException.loadFailed(
        archivePageIndex: archivePageIndex,
        cause: StateError('empty page bytes'),
      );
    }

    final Uint8List pngBytes;
    try {
      pngBytes = await _encodePng(sourceBytes);
    } on Object catch (error, stackTrace) {
      throw CopyPageImageException.encodeFailed(
        archivePageIndex: archivePageIndex,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _clipboardImage.writePng(pngBytes);
    } on Object catch (error, stackTrace) {
      throw CopyPageImageException.clipboardWriteFailed(
        archivePageIndex: archivePageIndex,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class CopyPageImageException extends AppException {
  CopyPageImageException._(super.message, {super.cause, super.stackTrace});

  factory CopyPageImageException.loadFailed({
    required int archivePageIndex,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return CopyPageImageException._(
      '加载页图失败（第 ${archivePageIndex + 1} 页）',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory CopyPageImageException.encodeFailed({
    required int archivePageIndex,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return CopyPageImageException._(
      '转换页图失败（第 ${archivePageIndex + 1} 页）',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory CopyPageImageException.clipboardWriteFailed({
    required int archivePageIndex,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return CopyPageImageException._(
      '写入剪贴板失败（第 ${archivePageIndex + 1} 页）',
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
