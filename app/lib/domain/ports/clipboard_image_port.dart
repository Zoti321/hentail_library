import 'dart:typed_data';

/// 系统图片剪贴板写入 seam。
abstract class ClipboardImagePort {
  Future<void> writePng(Uint8List pngBytes);
}
