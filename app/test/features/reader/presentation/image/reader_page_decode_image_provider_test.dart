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

  test('pageDecodeSizeForImageBytes leaves ordinary pages uncapped', () async {
    final Uint8List bytes = await _pngBytes(width: 40, height: 20);
    final PageDecodeSize size = await pageDecodeSizeForImageBytes(bytes);

    expect(size.capped, isFalse);
    expect(size.cacheWidth, isNull);
    expect(size.cacheHeight, isNull);
  });

  test(
    'pageDecodeSizeForImageBytes caps when maxEdge is below source long edge',
    () async {
      final Uint8List bytes = await _pngBytes(width: 40, height: 20);
      final PageDecodeSize size = await pageDecodeSizeForImageBytes(
        bytes,
        maxEdge: 20,
      );

      expect(size.capped, isTrue);
      expect(size.cacheWidth, 20);
      expect(size.cacheHeight, 10);
    },
  );

  test(
    'ReaderPageDecodeImageProvider obtainKey keeps null limits for ordinary pages',
    () async {
      final Uint8List bytes = await _pngBytes(width: 32, height: 16);
      final ReaderPageDecodeImageProvider provider =
          ReaderPageDecodeImageProvider(memoryBytes: bytes);

      final ReaderPageDecodeImageKey key = await provider.obtainKey(
        ImageConfiguration.empty,
      );

      expect(key.cacheWidth, isNull);
      expect(key.cacheHeight, isNull);
    },
  );

  test(
    'ReaderPageDecodeImageProvider obtainKey applies max-edge without viewport size',
    () async {
      final Uint8List bytes = await _pngBytes(width: 40, height: 20);
      final ReaderPageDecodeImageProvider provider =
          ReaderPageDecodeImageProvider(memoryBytes: bytes, maxEdge: 20);

      final ReaderPageDecodeImageKey key = await provider.obtainKey(
        ImageConfiguration.empty,
      );

      expect(key.cacheWidth, 20);
      expect(key.cacheHeight, 10);
    },
  );

  test(
    'buildReaderImageProvider returns a max-edge provider for page bytes',
    () {
      final ImageProvider<Object>? provider = buildReaderImageProvider(
        memoryBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(provider, isA<ReaderPageDecodeImageProvider>());
      final ReaderPageDecodeImageProvider typed =
          provider! as ReaderPageDecodeImageProvider;
      expect(typed.cacheWidth, isNull);
      expect(typed.cacheHeight, isNull);
      expect(typed.maxEdge, kReaderPageDecodeMaxEdge);
    },
  );
}
