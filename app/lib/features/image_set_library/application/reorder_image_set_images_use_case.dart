import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class ReorderImageSetImagesUseCase {
  const ReorderImageSetImagesUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(
    String libraryId,
    String imageSetId,
    List<String> orderedIds,
  ) => _repository.reorderImages(libraryId, imageSetId, orderedIds);
}