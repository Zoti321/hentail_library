import 'dart:typed_data';

import 'package:hentai_library/shared/application/errors/app_exception.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/clipboard_image_port.dart';

typedef PageImagePngEncoder = Future<Uint8List> Function(Uint8List imageBytes);

/// Session-aware page byte loader (Comic or Image set via OpenReadSessionService).
typedef CopyPageImageBytesLoader =
    Future<Uint8List?> Function({
      required String comicId,
      required int archivePageIndex,
    });

/// Copy a reader page to the clipboard (load → encode PNG → write).
///
/// PNG encoding is injected; the engine-backed default lives in data adapters.
class CopyPageImageService {
  CopyPageImageService({
    required this.loadPageBytes,
    required this.clipboardImage,
    required this.encodePng,
  });

  final CopyPageImageBytesLoader loadPageBytes;
  final ClipboardImagePort clipboardImage;
  final PageImagePngEncoder encodePng;

  Future<void> execute({
    required ReaderComicRef comic,
    required int archivePageIndex,
  }) async {
    final Uint8List? sourceBytes;
    try {
      sourceBytes = await loadPageBytes(
        comicId: comic.comicId,
        archivePageIndex: archivePageIndex,
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        CopyPageImageException.loadFailed(
          archivePageIndex: archivePageIndex,
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
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
      pngBytes = await encodePng(sourceBytes);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        CopyPageImageException.encodeFailed(
          archivePageIndex: archivePageIndex,
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }

    try {
      await clipboardImage.writePng(pngBytes);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        CopyPageImageException.clipboardWriteFailed(
          archivePageIndex: archivePageIndex,
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
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
