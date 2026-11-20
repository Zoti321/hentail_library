import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';

class LoadImageSetCatalogPageUseCase {
  const LoadImageSetCatalogPageUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<PagedImageSetCatalog> call({
    required String libraryId,
    required PageRequest request,
    required ImageSetBrowsePreferences preferences,
  }) => _repository.fetchCatalogPage(
    libraryId: libraryId,
    request: request,
    preferences: preferences,
  );
}
