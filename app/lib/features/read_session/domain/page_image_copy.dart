import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/ports/clipboard_image_port.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';

typedef PageImagePngEncoder = Future<Uint8List> Function(Uint8List imageBytes);

class PageImageCopy {
  PageImageCopy({
    required ComicPageSourcePort pageSource,
    required ClipboardImagePort clipboardImage,
    PageImagePngEncoder? encodePng,
  }) : _pageSource = pageSource,
       _clipboardImage = clipboardImage,
       _encodePng = encodePng ?? encodePageImagePng;

  final ComicPageSourcePort _pageSource;
  final ClipboardImagePort _clipboardImage;
  final PageImagePngEncoder _encodePng;

  Future<void> execute({
    required Comic comic,
    required int archivePageIndex,
  }) async {
    final Uint8List? sourceBytes;
    try {
      sourceBytes = await _pageSource.loadPageBytes(
        comic: comic,
        pageIndex: archivePageIndex,
      );
    } on Object catch (error, stackTrace) {
      throw PageImageCopyException.loadFailed(
        archivePageIndex: archivePageIndex,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (sourceBytes == null || sourceBytes.isEmpty) {
      throw PageImageCopyException.loadFailed(
        archivePageIndex: archivePageIndex,
        cause: StateError('empty page bytes'),
      );
    }

    final Uint8List pngBytes;
    try {
      pngBytes = await _encodePng(sourceBytes);
    } on Object catch (error, stackTrace) {
      throw PageImageCopyException.encodeFailed(
        archivePageIndex: archivePageIndex,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _clipboardImage.writePng(pngBytes);
    } on Object catch (error, stackTrace) {
      throw PageImageCopyException.clipboardWriteFailed(
        archivePageIndex: archivePageIndex,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

Future<Uint8List> encodePageImagePng(Uint8List imageBytes) async {
  final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
  try {
    final ui.FrameInfo frame = await codec.getNextFrame();
    try {
      final ByteData? pngData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (pngData == null) {
        throw StateError('png encode returned null');
      }
      return pngData.buffer.asUint8List();
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

class PageImageCopyException extends AppException {
  PageImageCopyException._(super.message, {super.cause, super.stackTrace});

  factory PageImageCopyException.loadFailed({
    required int archivePageIndex,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return PageImageCopyException._(
      '加载页图失败（第 ${archivePageIndex + 1} 页）',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory PageImageCopyException.encodeFailed({
    required int archivePageIndex,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return PageImageCopyException._(
      '转换页图失败（第 ${archivePageIndex + 1} 页）',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory PageImageCopyException.clipboardWriteFailed({
    required int archivePageIndex,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return PageImageCopyException._(
      '写入剪贴板失败（第 ${archivePageIndex + 1} 页）',
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
