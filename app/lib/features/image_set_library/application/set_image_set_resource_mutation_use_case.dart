import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class SetImageSetResourceMutationUseCase {
  const SetImageSetResourceMutationUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(String libraryId, {required bool enabled}) =>
      _repository.setResourceMutation(libraryId, enabled: enabled);
}