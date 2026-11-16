import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/mappers/image_set_frb_mapper.dart';
import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/image_set.dart' as rust;

class ImageSetRepositoryImpl implements ImageSetRepository {
  const ImageSetRepositoryImpl();

  @override
  Future<List<ImageSet>> listImageSets(String libraryId) => guardFrb(
    () async =>
        (await rust.listImageSetsFrb(libraryId: libraryId))
            .map(imageSetFromFrb)
            .toList(),
    fallbackMessage: '读取图集失败',
  );

  @override
  Future<List<ImageSetImage>> listImageSetImages(
    String libraryId,
    String imageSetId,
  ) => guardFrb(
    () async => (await rust.listImageSetImagesFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
    )).map(imageSetImageFromFrb).toList(),
    fallbackMessage: '读取图集图片失败',
  );
}
