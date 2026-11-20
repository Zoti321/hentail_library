import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

class UpdateImageSetNameUseCase {
  const UpdateImageSetNameUseCase(this._repository, this._events);

  final ImageSetRepository _repository;
  final DomainEventPublisher _events;

  Future<void> call(String imageSetId, String name) async {
    await _repository.updateName(imageSetId, name);
    _events.publish(const LibraryCatalogChanged());
  }
}