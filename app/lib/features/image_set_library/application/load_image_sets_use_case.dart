import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class LoadImageSetsUseCase {
  const LoadImageSetsUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<List<ImageSet>> call(String libraryId) =>
      _repository.listImageSets(libraryId);
}
