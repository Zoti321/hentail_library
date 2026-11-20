import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reader/presentation/image/page_decode_size_policy.dart';
import 'package:hentai_library/features/reader/presentation/image/reader_image_cache.dart';

Future<Uint8List> _pngBytes({required int width, required int height}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF112233),
  );
  final ui.Image image = await recorder.endRecording().toImage(width, height);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    clearReaderImageCache();
  });

  test('obtainKey is path identity without probing dimensions', () async {
    const ReaderPageDecodeImageProvider provider = ReaderPageDecodeImageProvider(
      filePath: '/virtual/page.png',
    );

    final ReaderPageDecodeImageKey key = await provider.obtainKey(
      ImageConfiguration.empty,
    );

    expect(key.path, '/virtual/page.png');
    expect(key.memoryBytes, isNull);
    expect(key.maxEdge, kReaderPageDecodeMaxEdge);
  });

  test('obtainKey uses identical memory bytes as identity', () async {
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
    final ReaderPageDecodeImageProvider provider = ReaderPageDecodeImageProvider(
      memoryBytes: bytes,
    );

    final ReaderPageDecodeImageKey key = await provider.obtainKey(
      ImageConfiguration.empty,
    );

    expect(key.path, isNull);
    expect(identical(key.memoryBytes, bytes), isTrue);
  });

  test('buildReaderImageProvider returns a max-edge provider for page bytes', () {
    final ImageProvider<Object>? provider = buildReaderImageProvider(
      memoryBytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(provider, isA<ReaderPageDecodeImageProvider>());
    final ReaderPageDecodeImageProvider typed =
        provider! as ReaderPageDecodeImageProvider;
    expect(typed.maxEdge, kReaderPageDecodeMaxEdge);
  });

  test(
    'loadImage caps decode when maxEdge is below source long edge',
    () async {
      final Uint8List bytes = await _pngBytes(width: 40, height: 20);
      final ReaderPageDecodeImageProvider provider =
          ReaderPageDecodeImageProvider(memoryBytes: bytes, maxEdge: 20);

      final ReaderPageDecodeImageKey key = await provider.obtainKey(
        ImageConfiguration.empty,
      );
      final ImageStreamCompleter completer = provider.loadImage(
        key,
        PaintingBinding.instance.instantiateImageCodecWithSize,
      );

      final ImageInfo info = await completer.completed;
      expect(info.image.width, 20);
      expect(info.image.height, 10);
      info.dispose();
    },
  );

  test(
    'loadImage keeps source resolution when within maxEdge',
    () async {
      final Uint8List bytes = await _pngBytes(width: 40, height: 20);
      final ReaderPageDecodeImageProvider provider =
          ReaderPageDecodeImageProvider(memoryBytes: bytes);

      final ReaderPageDecodeImageKey key = await provider.obtainKey(
        ImageConfiguration.empty,
      );
      final ImageStreamCompleter completer = provider.loadImage(
        key,
        PaintingBinding.instance.instantiateImageCodecWithSize,
      );

      final ImageInfo info = await completer.completed;
      expect(info.image.width, 40);
      expect(info.image.height, 20);
      info.dispose();
    },
  );
}

extension on ImageStreamCompleter {
  Future<ImageInfo> get completed {
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        removeListener(listener);
        completer.complete(info);
      },
      onError: (Object error, StackTrace? stackTrace) {
        removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );
    addListener(listener);
    return completer.future;
  }
}
