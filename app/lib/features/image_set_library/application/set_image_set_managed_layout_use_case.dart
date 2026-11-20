import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class SetImageSetManagedLayoutUseCase {
  const SetImageSetManagedLayoutUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<void> call(String libraryId, {required bool enabled}) =>
      _repository.setManagedLayout(libraryId, enabled: enabled);
}