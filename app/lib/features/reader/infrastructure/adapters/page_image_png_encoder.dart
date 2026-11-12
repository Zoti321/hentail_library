import 'dart:typed_data';
import 'dart:ui' as ui;

/// Engine-backed PNG encoder for [CopyPageImageService] (kept out of domain).
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
