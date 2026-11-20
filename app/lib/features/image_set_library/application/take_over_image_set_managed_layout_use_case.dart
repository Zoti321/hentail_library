import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

class TakeOverImageSetManagedLayoutUseCase {
  const TakeOverImageSetManagedLayoutUseCase(this._repository, this._events);

  final ImageSetRepository _repository;
  final DomainEventPublisher _events;

  Future<void> call(String libraryId, String imageSetId) async {
    await _repository.takeOverManagedLayout(libraryId, imageSetId);
    _events.publish(const LibraryCatalogChanged());
  }
}