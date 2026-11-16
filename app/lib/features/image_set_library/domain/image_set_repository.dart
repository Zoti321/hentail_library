import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';

/// Image set 目录读取契约（owner：`image_set_library`）。结果顺序即 catalog 顺序。
abstract interface class ImageSetRepository {
  Future<List<ImageSet>> listImageSets(String libraryId);

  Future<List<ImageSetImage>> listImageSetImages(
    String libraryId,
    String imageSetId,
  );

  /// 打开 Read session（只读，不写 Comic 阅读历史）。
  Future<ImageSetReaderSession> openReaderSession(
    String libraryId,
    String imageSetId,
    int startIndex,
  );

  /// 按 catalog 载体读取单页原始字节。
  Future<Uint8List> loadPageBytes(String libraryId, ImageSetImage image);
}
