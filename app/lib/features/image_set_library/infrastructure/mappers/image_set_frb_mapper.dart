import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/src/rust/api/image_set.dart' as rust;

ImageSet imageSetFromFrb(rust.ImageSetDto dto) => ImageSet(
  imageSetId: dto.imageSetId,
  libraryId: dto.libraryId,
  relativePath: dto.relativePath,
  name: dto.name,
  isRoot: dto.isRoot,
  nameLocked: dto.nameLocked,
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

rust.ImageSetImageDto imageSetImageToFrb(ImageSetImage image) =>
    rust.ImageSetImageDto(
      imageSetImageId: image.imageSetImageId,
      imageSetId: image.imageSetId,
      libraryId: image.libraryId,
      carrierRelativePath: image.carrierRelativePath,
      memberPath: image.memberPath,
      carrierKind: image.carrierKind,
      name: image.name,
    );

ImageSetLibraryGates imageSetLibraryGatesFromFrb(
  rust.ImageSetLibraryGatesDto dto,
) => ImageSetLibraryGates(
  resourceMutation: dto.resourceMutation,
  managedLayout: dto.managedLayout,
);

ImageSetSubmission imageSetSubmissionFromFrb(rust.ImageSetSubmissionDto dto) =>
    ImageSetSubmission(
      submissionId: dto.submissionId,
      libraryId: dto.libraryId,
      imageSetId: dto.imageSetId,
      name: dto.name,
      memberImageIds: List<String>.from(dto.memberImageIds),
    );
