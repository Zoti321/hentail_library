import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/domain/comic_catalog_repository.dart';
import 'package:hentai_library/features/library_browse/domain/comic_user_metadata_repository.dart';

Never _unimplemented(String name) =>
    throw UnimplementedError('$name 未注入，请在 bootstrap 中 override');

final Provider<ComicCatalogRepository> comicCatalogRepositoryProvider =
    Provider<ComicCatalogRepository>(
      (Ref ref) => _unimplemented('comicCatalogRepositoryProvider'),
    );

final Provider<ComicUserMetadataRepository>
comicUserMetadataRepositoryProvider = Provider<ComicUserMetadataRepository>(
  (Ref ref) => _unimplemented('comicUserMetadataRepositoryProvider'),
);
