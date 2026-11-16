import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/src/rust/api/image_set.dart' as rust;

ImageSet imageSetFromFrb(rust.ImageSetDto dto) => ImageSet(
  imageSetId: dto.imageSetId,
  libraryId: dto.libraryId,
  relativePath: dto.relativePath,
  name: dto.name,
  isRoot: dto.isRoot,
);

ImageSetImage imageSetImageFromFrb(rust.ImageSetImageDto dto) => ImageSetImage(
  imageSetImageId: dto.imageSetImageId,
  imageSetId: dto.imageSetId,
  libraryId: dto.libraryId,
  carrierRelativePath: dto.carrierRelativePath,
  memberPath: dto.memberPath,
  carrierKind: dto.carrierKind,
  name: dto.name,
);
