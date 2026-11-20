import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class LoadImageSetFacetsUseCase {
  const LoadImageSetFacetsUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<ImageSetFacets> call(String imageSetId) =>
      _repository.fetchFacets(imageSetId);
}
