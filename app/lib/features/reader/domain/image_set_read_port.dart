import 'dart:typed_data';

import 'package:hentai_library/features/reader/domain/image_set_navigation.dart';

/// Reader-owned Image set page descriptor（避免 reader → image_set_library 依赖）。
class ImageSetReadPage {
  const ImageSetReadPage({
    required this.imageSetImageId,
    required this.imageSetId,
    required this.libraryId,
    required this.carrierRelativePath,
    required this.memberPath,
    required this.carrierKind,
    required this.name,
    required this.index,
  });

  final String imageSetImageId;
  final String imageSetId;
  final String libraryId;
  final String carrierRelativePath;
  final String memberPath;
  final String carrierKind;
  final String name;

  /// 0-based catalog index within the Image set.
  final int index;
}

class ImageSetOpenedReadSession {
  const ImageSetOpenedReadSession({
    required this.libraryId,
    required this.imageSetId,
    required this.title,
    required this.pages,
    required this.startIndex,
  });

  final String libraryId;
  final String imageSetId;
  final String title;
  final List<ImageSetReadPage> pages;

  /// 0-based start index (clamped by the port / core).
  final int startIndex;
}

/// Image set Read session IO seam（composition 绑定 image_set_library repository）。
abstract class ImageSetReadPort {
  Future<ImageSetOpenedReadSession> openSession({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  });

  Future<Uint8List> loadPageBytes(ImageSetReadPage page);

  /// Non-empty Image sets of [libraryId] in Image set catalog order.
  Future<List<ImageSetNavItem>> listNavigableImageSets({
    required String libraryId,
  });
}
