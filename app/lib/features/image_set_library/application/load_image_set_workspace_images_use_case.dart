import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class LoadImageSetWorkspaceImagesUseCase {
  const LoadImageSetWorkspaceImagesUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<List<ImageSetImage>> call(String libraryId, String imageSetId) =>
      _repository.listWorkspaceImages(libraryId, imageSetId);
}