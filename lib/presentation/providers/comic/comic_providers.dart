import 'package:hentai_library/data/repository/comic_repo.dart';
import 'package:hentai_library/data/services/comic/comic.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart' as domain;
import 'package:hentai_library/domain/usecases/usecases.dart';
import 'package:hentai_library/presentation/providers/core/core_providers.dart';
import 'package:hentai_library/presentation/providers/directory/directory_providers.dart';
import 'package:hentai_library/presentation/providers/reading_history/reading_history_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_providers.g.dart';

@Riverpod()
DirectoryParseService folderParseService(Ref ref) => DirectoryParseService();

@Riverpod(keepAlive: true)
ComicFileCacheService comicFileCacheService(Ref ref) => ComicFileCacheService();

@Riverpod(keepAlive: true)
ComicScannerService comicScannerService(Ref ref) {
  return ComicScannerService(
    cacheService: ref.read(comicFileCacheServiceProvider),
  );
}

@Riverpod(keepAlive: true)
CoverRepairService coverRepairService(Ref ref) {
  return CoverRepairService(
    scannerService: ref.read(comicScannerServiceProvider),
  );
}

@Riverpod(keepAlive: true)
ComicSyncService comicSyncService(Ref ref) {
  return ComicSyncService(
    ref.read(comicDaoProvider),
    ref.read(folderParseServiceProvider),
    ref.read(comicScannerServiceProvider),
    ref.read(comicFileCacheServiceProvider),
  );
}

@Riverpod(keepAlive: true)
domain.ComicRepository comicRepo(Ref ref) {
  return ComicRepositoryImpl(
    ref.read(comicDaoProvider),
    ref.read(categoryTagDaoProvider),
    ref.read(comicSyncServiceProvider),
    ref.read(comicFileCacheServiceProvider),
  );
}

@Riverpod(keepAlive: true)
SyncComicsUseCase syncComicsUseCase(Ref ref) {
  return SyncComicsUseCase(
    ref.read(comicRepoProvider),
    ref.read(dirRepoProvider),
  );
}

@Riverpod(keepAlive: true)
UpdateComicMetadataUseCase updateComicMetadataUseCase(Ref ref) {
  return UpdateComicMetadataUseCase(ref.read(comicRepoProvider));
}

@Riverpod(keepAlive: true)
ArchiveChaptersUseCase archiveChaptersUseCase(Ref ref) {
  return ArchiveChaptersUseCase(ref.read(comicRepoProvider));
}

@Riverpod(keepAlive: true)
IncrementReadCountUseCase incrementReadCountUseCase(Ref ref) {
  return IncrementReadCountUseCase(ref.read(comicRepoProvider));
}

@Riverpod(keepAlive: true)
RecordReadingProgressUseCase recordReadingProgressUseCase(Ref ref) {
  return RecordReadingProgressUseCase(ref.read(readingHistoryRepoProvider));
}

@Riverpod(keepAlive: true)
Future<int> comicCacheSize(Ref ref) {
  return ref.watch(comicFileCacheServiceProvider).getCacheDiskUsage();
}

/// 扫描漫画库是否进行中。用于单例约束：扫描中不允许再打开新扫描对话框。
@Riverpod(keepAlive: true)
class ScanInProgressNotifier extends _$ScanInProgressNotifier {
  @override
  bool build() => false;

  void setInProgress(bool value) => state = value;
}
