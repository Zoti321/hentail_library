import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';

/// Image set 目录读取契约（owner：`image_set_library`）。结果顺序即 catalog 顺序。
abstract interface class ImageSetRepository {
  Future<List<ImageSet>> listImageSets(String libraryId);

  Future<List<ImageSetImage>> listImageSetImages(
    String libraryId,
    String imageSetId,
  );
}
