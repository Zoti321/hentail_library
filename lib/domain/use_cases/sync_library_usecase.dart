import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/library_scan_port.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/domain/use_cases/delete_comics_usecase.dart';
import 'package:hentai_library/domain/use_cases/generate_comic_thumbnails_usecase.dart';
import 'package:hentai_library/domain/use_cases/sync_library_types.dart';

/// 用例：同步漫画库（扫描根路径、写库、无根清空）。
class SyncLibraryUseCase {
  SyncLibraryUseCase({
    required PathRepository pathRepository,
    required ComicRepository comicRepository,
    required ComicThumbnailRepository comicThumbnailRepository,
    required DeleteComicsUseCase deleteComicsUseCase,
    required GenerateComicThumbnailsUseCase generateComicThumbnailsUseCase,
    required LibraryScanPort libraryScanPort,
    required ReaderSessionPort readerSessionPort,
  }) : _pathRepository = pathRepository,
       _comicRepository = comicRepository,
       _comicThumbnailRepository = comicThumbnailRepository,
       _deleteComicsUseCase = deleteComicsUseCase,
       _generateComicThumbnailsUseCase = generateComicThumbnailsUseCase,
       _libraryScanPort = libraryScanPort,
       _readerSessionPort = readerSessionPort;

  final PathRepository _pathRepository;
  final ComicRepository _comicRepository;
  final ComicThumbnailRepository _comicThumbnailRepository;
  final DeleteComicsUseCase _deleteComicsUseCase;
  final GenerateComicThumbnailsUseCase _generateComicThumbnailsUseCase;
  final LibraryScanPort _libraryScanPort;
  final ReaderSessionPort _readerSessionPort;

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

  SyncLibraryProgress _withRootsProgress({
    required SyncLibraryPhase phase,
    required String? currentPath,
    required int acceptedTotal,
    required LibrarySyncCounts counts,
    int? removedCount,
    int? addedCount,
    int? keptCount,
    int? thumbnailTotal,
    int? thumbnailDone,
    int? thumbnailFailedCount,
  }) {
    return (
      phase: phase,
      route: SyncLibraryRoute.withRoots,
      currentPath: currentPath,
      acceptedTotal: acceptedTotal,
      counts: counts,
      removedCount: removedCount,
      addedCount: addedCount,
      keptCount: keptCount,
      thumbnailTotal: thumbnailTotal,
      thumbnailDone: thumbnailDone,
      thumbnailFailedCount: thumbnailFailedCount,
    );
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
          thumbnailTotal: null,
          thumbnailDone: null,
          thumbnailFailedCount: null,
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
        thumbnailTotal: null,
        thumbnailDone: null,
        thumbnailFailedCount: null,
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
        thumbnailTotal: null,
        thumbnailDone: null,
        thumbnailFailedCount: null,
      ));
      await _deleteComicsUseCase(ids);
      emit((
        phase: SyncLibraryPhase.done,
        route: SyncLibraryRoute.noRootsCleared,
        currentPath: null,
        acceptedTotal: 0,
        counts: emptyLibrarySyncCounts(),
        removedCount: ids.length,
        addedCount: 0,
        keptCount: 0,
        thumbnailTotal: null,
        thumbnailDone: null,
        thumbnailFailedCount: null,
      ));
      return;
    }
    var counts = emptyLibrarySyncCounts();
    var acceptedTotal = 0;
    final comics = <Comic>[];
    await for (final LibraryScanItem item in _libraryScanPort.scanRoots(
      effectiveRoots,
      isCancelled: isCancelled,
    )) {
      if (isCancelled?.call() == true) {
        return;
      }
      emit(
        _withRootsProgress(
          phase: SyncLibraryPhase.scanning,
          currentPath: item.path,
          acceptedTotal: acceptedTotal,
          counts: counts,
        ),
      );
      counts = _bump(counts, item.resourceType);
      acceptedTotal++;
      comics.add(item.comic);
      emit(
        _withRootsProgress(
          phase: SyncLibraryPhase.scanning,
          currentPath: item.path,
          acceptedTotal: acceptedTotal,
          counts: counts,
        ),
      );
    }
    if (isCancelled?.call() == true) {
      return;
    }
    emit(
      _withRootsProgress(
        phase: SyncLibraryPhase.writingDb,
        currentPath: null,
        acceptedTotal: acceptedTotal,
        counts: counts,
      ),
    );
    final plan = await _comicRepository.buildScanReplacePlan(
      List<Comic>.from(comics),
    );
    if (plan.removedIds.isNotEmpty) {
      await _deleteComicsUseCase(plan.removedIds);
    }
    if (plan.thumbnailInvalidatedComicIds.isNotEmpty) {
      await _comicThumbnailRepository.deleteByComicIds(
        plan.thumbnailInvalidatedComicIds,
      );
    }
    await _comicRepository.upsertMany(plan.toUpsert);
    await _readerSessionPort.clear();
    final List<Comic> thumbnailTargets = plan.thumbnailGenerationTargets;
    var thumbnailFailedCount = 0;
    if (thumbnailTargets.isNotEmpty) {
      if (isCancelled?.call() == true) {
        return;
      }
      final int thumbnailTotal = thumbnailTargets.length;
      emit(
        _withRootsProgress(
          phase: SyncLibraryPhase.generatingThumbnails,
          currentPath: null,
          acceptedTotal: acceptedTotal,
          counts: counts,
          removedCount: plan.removedIds.length,
          addedCount: plan.addedCount,
          keptCount: plan.keptCount,
          thumbnailTotal: thumbnailTotal,
          thumbnailDone: 0,
          thumbnailFailedCount: 0,
        ),
      );
      final GenerateComicThumbnailsResult result =
          await _generateComicThumbnailsUseCase(
            targets: thumbnailTargets,
            isCancelled: isCancelled,
            onProgress: (GenerateComicThumbnailsProgress progress) {
              if (isCancelled?.call() == true) {
                return;
              }
              emit(
                _withRootsProgress(
                  phase: SyncLibraryPhase.generatingThumbnails,
                  currentPath: progress.currentPath,
                  acceptedTotal: acceptedTotal,
                  counts: counts,
                  removedCount: plan.removedIds.length,
                  addedCount: plan.addedCount,
                  keptCount: plan.keptCount,
                  thumbnailTotal: thumbnailTotal,
                  thumbnailDone: progress.done,
                  thumbnailFailedCount: progress.failedCount,
                ),
              );
            },
          );
      if (isCancelled?.call() == true) {
        return;
      }
      thumbnailFailedCount = result.failedCount;
    }
    emit(
      _withRootsProgress(
        phase: SyncLibraryPhase.done,
        currentPath: null,
        acceptedTotal: acceptedTotal,
        counts: counts,
        removedCount: plan.removedIds.length,
        addedCount: plan.addedCount,
        keptCount: plan.keptCount,
        thumbnailTotal: thumbnailTargets.isEmpty
            ? null
            : thumbnailTargets.length,
        thumbnailDone: thumbnailTargets.isEmpty
            ? null
            : thumbnailTargets.length,
        thumbnailFailedCount: thumbnailTargets.isEmpty
            ? null
            : thumbnailFailedCount,
      ),
    );
  }
}
