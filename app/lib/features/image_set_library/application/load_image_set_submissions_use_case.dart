import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';

class LoadImageSetSubmissionsUseCase {
  const LoadImageSetSubmissionsUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<List<ImageSetSubmission>> call(
    String libraryId,
    String imageSetId,
  ) => _repository.listSubmissions(libraryId, imageSetId);
}