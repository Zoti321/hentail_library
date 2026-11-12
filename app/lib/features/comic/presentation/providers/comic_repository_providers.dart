import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_catalog_repository.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_user_metadata_repository.dart';

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

/// 漫画 lookup Repository：reader 只经 `ComicReadQuery`，本 token 归 comic（ADR-0045）。
final Provider<ComicLookupRepository> comicLookupRepositoryProvider =
    Provider<ComicLookupRepository>(
      (Ref ref) => _unimplemented('comicLookupRepositoryProvider'),
    );

/// 漫画缩略图 Repository（含系列封面读写）：cross-feature 经 `comic/public.dart`。
final Provider<ComicThumbnailRepository> comicThumbnailRepoProvider =
    Provider<ComicThumbnailRepository>(
      (Ref ref) => _unimplemented('comicThumbnailRepoProvider'),
    );
