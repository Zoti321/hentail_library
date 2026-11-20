import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

class SetImageSetNameLockedUseCase {
  const SetImageSetNameLockedUseCase(this._repository, this._events);

  final ImageSetRepository _repository;
  final DomainEventPublisher _events;

  Future<void> call(String imageSetId, {required bool locked}) async {
    await _repository.setNameLocked(imageSetId, locked: locked);
    _events.publish(const LibraryCatalogChanged());
  }
}