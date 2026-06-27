import 'package:hentai_library/domain/use_cases/sync_library_usecase.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_library.g.dart';

@Riverpod(keepAlive: true)
SyncLibraryUseCase syncLibraryUseCase(Ref ref) => SyncLibraryUseCase(
  pathRepository: ref.read(pathRepoProvider),
  comicRepository: ref.read(comicRepoProvider),
  readingHistoryRepository: ref.read(readingHistoryRepoProvider),
  seriesRepository: ref.read(librarySeriesRepoProvider),
  scanParseService: ref.read(comicScanParseServiceProvider),
  comicMapper: ref.read(libraryComicMapperProvider),
  readResourceGetService: ref.read(readResourceGetServiceProvider),
);
