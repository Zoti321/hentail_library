import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/usecases/purge_comics_side_effects.dart';
import 'package:hentai_library/domain/usecases/usecases.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:hentai_library/presentation/providers/usecases/sync_library_progress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_library.g.dart';

@Riverpod(keepAlive: true)
SyncComicsUseCase syncComicsUseCase(Ref ref) => SyncComicsUseCase(ref);

@Riverpod(keepAlive: true)
RecordReadingProgressUseCase recordReadingProgressUseCase(Ref ref) {
  return RecordReadingProgressUseCase(ref.read(readingHistoryRepoProvider));
}

class SyncComicsUseCase {
  SyncComicsUseCase(this._ref);

  final Ref _ref;

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

    // 1. 通过 path 仓储获取所有选中的路径
    final dirs = await _ref.read(pathRepoProvider).getAll();
    final effectiveRoots = dirs
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (effectiveRoots.isEmpty) {
      if (isCancelled?.call() == true) {
        return;
      }

      final repo = _ref.read(libraryComicRepoProvider);
      final existing = await repo.getAll();
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

      final historyRepo = _ref.read(readingHistoryRepoProvider);
      final seriesRepo = _ref.read(librarySeriesRepoProvider);

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
        libraryComics: repo,
        readingHistory: historyRepo,
        librarySeries: seriesRepo,
        comicIds: ids,
      );

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

    final scanParse = _ref.read(comicScanParseServiceProvider);
    final mapper = _ref.read(libraryComicMapperProvider);
    final repo = _ref.read(libraryComicRepoProvider);

    var counts = emptyLibrarySyncCounts();
    var acceptedTotal = 0;
    final comics = <Comic>[];

    await for (final p in scanParse.scanAndParseRoots(
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
      comics.add(mapper.fromParsedResource(p));
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

    final apply = await repo.replaceByScan(List<Comic>.from(comics));

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
