import 'package:hentai_library/features/image_set_library/domain/image_set_facets_patch.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

class UpdateImageSetFacetsUseCase {
  const UpdateImageSetFacetsUseCase(this._repository, this._events);

  final ImageSetRepository _repository;
  final DomainEventPublisher _events;

  Future<void> call(String imageSetId, ImageSetFacetsPatch patch) async {
    await _repository.updateFacets(imageSetId, patch);
    _events.publish(
      ComicMetadataPersisted(
        tagsWritten: patch.tags != null,
        authorsWritten: patch.authors != null,
        parodiesWritten: patch.parodies != null,
        charactersWritten: patch.characters != null,
      ),
    );
  }
}