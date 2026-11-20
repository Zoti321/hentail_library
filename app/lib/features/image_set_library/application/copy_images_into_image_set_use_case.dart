import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

class CopyImagesIntoImageSetUseCase {
  const CopyImagesIntoImageSetUseCase(this._repository, this._events);

  final ImageSetRepository _repository;
  final DomainEventPublisher _events;

  Future<List<ImageSetImage>> call(
    String libraryId,
    String imageSetId,
    List<String> sourcePaths,
  ) async {
    final List<ImageSetImage> added = await _repository.copyImagesIn(
      libraryId,
      imageSetId,
      sourcePaths,
    );
    if (added.isNotEmpty) {
      _events.publish(const LibraryCatalogChanged());
    }
    return added;
  }
}