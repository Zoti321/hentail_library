import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';

class CreateImageSetSubmissionUseCase {
  const CreateImageSetSubmissionUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<ImageSetSubmission> call(
    String libraryId,
    String imageSetId,
    String name,
  ) => _repository.createSubmission(libraryId, imageSetId, name);
}