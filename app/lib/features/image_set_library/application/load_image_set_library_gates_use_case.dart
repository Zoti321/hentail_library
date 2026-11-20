import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class LoadImageSetLibraryGatesUseCase {
  const LoadImageSetLibraryGatesUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<ImageSetLibraryGates> call(String libraryId) =>
      _repository.getLibraryGates(libraryId);
}