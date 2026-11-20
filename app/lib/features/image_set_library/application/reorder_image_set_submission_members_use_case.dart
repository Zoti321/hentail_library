import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class ReorderImageSetSubmissionMembersUseCase {
  const ReorderImageSetSubmissionMembersUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(
    String libraryId,
    String submissionId,
    List<String> orderedIds,
  ) => _repository.reorderSubmissionMembers(
    libraryId,
    submissionId,
    orderedIds,
  );
}