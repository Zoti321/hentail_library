import 'package:hentai_library/features/comic/infrastructure/comic_repository_impl.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_catalog_repository.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_user_metadata_repository.dart';

/// Bootstrap / 测试注入用工厂（lookup / catalog / user metadata 共用 impl）。
ComicLookupRepository createComicRepository() => const ComicRepositoryImpl();

/// 与 [createComicRepository] 相同实例类型，供 catalog token override。
ComicCatalogRepository createComicCatalogRepository() =>
    const ComicRepositoryImpl();

/// 与 [createComicRepository] 相同实例类型，供 user metadata token override。
ComicUserMetadataRepository createComicUserMetadataRepository() =>
    const ComicRepositoryImpl();
