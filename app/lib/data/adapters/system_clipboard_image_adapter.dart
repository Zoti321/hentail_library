import 'dart:typed_data';

import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/domain/ports/clipboard_image_port.dart';
import 'package:super_clipboard/super_clipboard.dart';

class SystemClipboardImageAdapter implements ClipboardImagePort {
  const SystemClipboardImageAdapter();

  @override
  Future<void> writePng(Uint8List pngBytes) async {
    final SystemClipboard? clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      throw AppException('当前平台不支持图片剪贴板');
    }
    final DataWriterItem item = DataWriterItem()..add(Formats.png(pngBytes));
    await clipboard.write(<DataWriterItem>[item]);
  }
}
