import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';

/// Image set Read session 快照：catalog 顺序的页列表与起始页（0-based）。
class ImageSetReaderSession {
  const ImageSetReaderSession({
    required this.libraryId,
    required this.imageSetId,
    required this.pages,
    required this.startIndex,
  });

  final String libraryId;
  final String imageSetId;
  final List<ImageSetImage> pages;
  final int startIndex;
}
