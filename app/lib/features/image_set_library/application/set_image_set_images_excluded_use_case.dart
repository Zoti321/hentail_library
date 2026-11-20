import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class SetImageSetImagesExcludedUseCase {
  const SetImageSetImagesExcludedUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(
    String libraryId,
    String imageSetId,
    List<String> imageIds, {
    required bool excluded,
  }) => _repository.setImagesExcluded(
    libraryId,
    imageSetId,
    imageIds,
    excluded: excluded,
  );
}