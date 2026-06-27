import 'package:hentai_library/data/mappers/mapping.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/api/read_resource_get_service.dart';
import 'package:hentai_library/data/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/domain/use_cases/purge_comics_side_effects.dart';
import 'package:hentai_library/domain/use_cases/sync_library_types.dart';

/// 用例：同步漫画库（扫描根路径、写库、无根清空）。
class SyncLibraryUseCase {
  SyncLibraryUseCase({
    required PathRepository pathRepository,
    required ComicRepository comicRepository,
    required ReadingHistoryRepository readingHistoryRepository,
    required SeriesRepository seriesRepository,
    required ComicScanParseService scanParseService,
    required ComicMapper comicMapper,
    required ReadResourceGetService readResourceGetService,
  }) : _pathRepository = pathRepository,
       _comicRepository = comicRepository,
       _readingHistoryRepository = readingHistoryRepository,
       _seriesRepository = seriesRepository,
       _scanParseService = scanParseService,
       _comicMapper = comicMapper,
       _readResourceGetService = readResourceGetService;

  final PathRepository _pathRepository;
  final ComicRepository _comicRepository;
  final ReadingHistoryRepository _readingHistoryRepository;
  final SeriesRepository _seriesRepository;
  final ComicScanParseService _scanParseService;
  final ComicMapper _comicMapper;
  final ReadResourceGetService _readResourceGetService;

  LibrarySyncCounts _bump(LibrarySyncCounts c, ResourceType t) {
    return switch (t) {
      ResourceType.dir => (
        dir: c.dir + 1,
        zip: c.zip,
        cbz: c.cbz,
        epub: c.epub,
      ),
      ResourceType.zip => (
        dir: c.dir,
        zip: c.zip + 1,
        cbz: c.cbz,
        epub: c.epub,
      ),
      ResourceType.cbz => (
        dir: c.dir,
        zip: c.zip,
        cbz: c.cbz + 1,
        epub: c.epub,
      ),
      ResourceType.epub => (
        dir: c.dir,
        zip: c.zip,
        cbz: c.cbz,
        epub: c.epub + 1,
      ),
      ResourceType.cbr => c,
      ResourceType.rar => c,
    };
  }

  Future<void> call({
    bool Function()? isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) async {
    void emit(SyncLibraryProgress p) => onProgress?.call(p);
    final dirs = await _pathRepository.getAll();
    final effectiveRoots = dirs
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (effectiveRoots.isEmpty) {
      if (isCancelled?.call() == true) {
        return;
      }
      final existing = await _comicRepository.getAll();
      if (existing.isEmpty) {
        emit((
          phase: SyncLibraryPhase.done,
          route: SyncLibraryRoute.noRootsNoop,
          currentPath: null,
          acceptedTotal: 0,
          counts: emptyLibrarySyncCounts(),
          removedCount: null,
          addedCount: null,
          keptCount: null,
        ));
        return;
      }
      final ids = existing.map((e) => e.comicId).toList();
      emit((
        phase: SyncLibraryPhase.clearingLibrary,
        route: SyncLibraryRoute.noRootsCleared,
        currentPath: null,
        acceptedTotal: 0,
        counts: emptyLibrarySyncCounts(),
        removedCount: null,
        addedCount: null,
        keptCount: null,
      ));
      emit((
        phase: SyncLibraryPhase.writingDb,
        route: SyncLibraryRoute.noRootsCleared,
        currentPath: null,
        acceptedTotal: 0,
        counts: emptyLibrarySyncCounts(),
        removedCount: null,
        addedCount: null,
        keptCount: null,
      ));
      await purgeComicsFromApp(
        libraryComics: _comicRepository,
        readingHistory: _readingHistoryRepository,
        librarySeries: _seriesRepository,
        comicIds: ids,
      );
      await _seriesRepository.removeOrphanSeriesItems();
      await _readResourceGetService.clear();
      emit((
        phase: SyncLibraryPhase.done,
        route: SyncLibraryRoute.noRootsCleared,
        currentPath: null,
        acceptedTotal: 0,
        counts: emptyLibrarySyncCounts(),
        removedCount: ids.length,
        addedCount: 0,
        keptCount: 0,
      ));
      return;
    }
    var counts = emptyLibrarySyncCounts();
    var acceptedTotal = 0;
    final comics = <Comic>[];
    await for (final p in _scanParseService.scanAndParseRoots(
      effectiveRoots,
      isCancelled: isCancelled,
    )) {
      if (isCancelled?.call() == true) {
        return;
      }
      emit((
        phase: SyncLibraryPhase.scanning,
        route: SyncLibraryRoute.withRoots,
        currentPath: p.path,
        acceptedTotal: acceptedTotal,
        counts: counts,
        removedCount: null,
        addedCount: null,
        keptCount: null,
      ));
      counts = _bump(counts, p.type);
      acceptedTotal++;
      comics.add(_comicMapper.fromParsedResource(p));
      emit((
        phase: SyncLibraryPhase.scanning,
        route: SyncLibraryRoute.withRoots,
        currentPath: p.path,
        acceptedTotal: acceptedTotal,
        counts: counts,
        removedCount: null,
        addedCount: null,
        keptCount: null,
      ));
    }
    if (isCancelled?.call() == true) {
      return;
    }
    emit((
      phase: SyncLibraryPhase.writingDb,
      route: SyncLibraryRoute.withRoots,
      currentPath: null,
      acceptedTotal: acceptedTotal,
      counts: counts,
      removedCount: null,
      addedCount: null,
      keptCount: null,
    ));
    final apply = await _comicRepository.replaceByScan(List<Comic>.from(comics));
    await _seriesRepository.removeOrphanSeriesItems();
    await _readResourceGetService.clear();
    emit((
      phase: SyncLibraryPhase.done,
      route: SyncLibraryRoute.withRoots,
      currentPath: null,
      acceptedTotal: acceptedTotal,
      counts: counts,
      removedCount: apply.removedCount,
      addedCount: apply.addedCount,
      keptCount: apply.keptCount,
    ));
  }
}
