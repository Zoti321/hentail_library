import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class DeleteImageSetSubmissionUseCase {
  const DeleteImageSetSubmissionUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(String libraryId, String submissionId) =>
      _repository.deleteSubmission(libraryId, submissionId);
}