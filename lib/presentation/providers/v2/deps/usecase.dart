// == usecase ==
import 'package:hentai_library/domain/usecases/assign_library_comic_to_series_usecase.dart';
import 'package:hentai_library/domain/usecases/ingest_library_resources_usecase.dart';
import 'package:hentai_library/domain/usecases/update_library_comic_meta_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'deps.dart';

part 'usecase.g.dart';

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
