import 'package:hentai_library/data/repository/v2/library_comic_repo_impl.dart';
import 'package:hentai_library/data/repository/v2/library_series_repo_impl.dart';
import 'package:hentai_library/data/repository/v2/library_tag_repo_impl.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:hentai_library/data/services/comic/resource_scanner.dart';
import 'package:hentai_library/domain/mappers/library_comic_mapper.dart';
import 'package:hentai_library/domain/repository/library_comic_repo.dart';
import 'package:hentai_library/domain/repository/library_series_repo.dart';
import 'package:hentai_library/domain/repository/library_tag_repo.dart';
import 'package:hentai_library/domain/usecases/assign_library_comic_to_series_usecase.dart';
import 'package:hentai_library/domain/usecases/ingest_library_resources_usecase.dart';
import 'package:hentai_library/domain/usecases/update_library_comic_meta_usecase.dart';
import 'package:hentai_library/presentation/providers/core/core_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_deps_providers.g.dart';

@Riverpod(keepAlive: true)
LibraryComicDao libraryComicDao(Ref ref) =>
    LibraryComicDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
LibrarySeriesDao librarySeriesDao(Ref ref) =>
    LibrarySeriesDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
LibraryTagDao libraryTagDao(Ref ref) =>
    LibraryTagDao(ref.read(databaseProvider));

@Riverpod(keepAlive: true)
LibraryComicRepository libraryComicRepo(Ref ref) =>
    LibraryComicRepositoryImpl(ref.read(libraryComicDaoProvider));

@Riverpod(keepAlive: true)
LibrarySeriesRepository librarySeriesRepo(Ref ref) =>
    LibrarySeriesRepositoryImpl(ref.read(librarySeriesDaoProvider));

@Riverpod(keepAlive: true)
LibraryTagRepository libraryTagRepo(Ref ref) =>
    LibraryTagRepositoryImpl(ref.read(libraryTagDaoProvider));

@Riverpod(keepAlive: true)
ResourceScanner resourceScanner(Ref ref) => ResourceScanner();

@Riverpod(keepAlive: true)
ResourceParser resourceParser(Ref ref) => ResourceParser();

@Riverpod(keepAlive: true)
LibraryComicMapper libraryComicMapper(Ref ref) => LibraryComicMapper();

@Riverpod(keepAlive: true)
IngestLibraryResourcesUseCase ingestLibraryResourcesUseCase(Ref ref) {
  return IngestLibraryResourcesUseCase(
    scanner: ref.read(resourceScannerProvider),
    parser: ref.read(resourceParserProvider),
    mapper: ref.read(libraryComicMapperProvider),
    comicRepo: ref.read(libraryComicRepoProvider),
  );
}

@Riverpod(keepAlive: true)
UpdateLibraryComicMetaUseCase updateLibraryComicMetaUseCase(Ref ref) {
  return UpdateLibraryComicMetaUseCase(ref.read(libraryComicRepoProvider));
}

@Riverpod(keepAlive: true)
AssignLibraryComicToSeriesUseCase assignLibraryComicToSeriesUseCase(Ref ref) {
  return AssignLibraryComicToSeriesUseCase(ref.read(librarySeriesRepoProvider));
}
