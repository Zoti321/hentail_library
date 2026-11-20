import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class RenameImageSetSubmissionUseCase {
  const RenameImageSetSubmissionUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(String libraryId, String submissionId, String name) =>
      _repository.renameSubmission(libraryId, submissionId, name);
}