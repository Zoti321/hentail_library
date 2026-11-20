import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class AddImageSetSubmissionMembersUseCase {
  const AddImageSetSubmissionMembersUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  ) => _repository.addSubmissionMembers(libraryId, submissionId, imageIds);
}