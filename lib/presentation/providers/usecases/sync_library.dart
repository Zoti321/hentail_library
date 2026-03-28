import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/usecases/usecases.dart';
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

@Riverpod(keepAlive: true)
class ScanInProgressNotifier extends _$ScanInProgressNotifier {
  @override
  bool build() => false;

  void setInProgress(bool value) => state = value;
}

class SyncComicsUseCase {
  SyncComicsUseCase(this._ref);

  final Ref _ref;

  LibrarySyncCounts _bump(LibrarySyncCounts c, ResourceType t) {
    return switch (t) {
      ResourceType.dir => (dir: c.dir + 1, zip: c.zip, cbz: c.cbz, epub: c.epub),
      ResourceType.zip => (dir: c.dir, zip: c.zip + 1, cbz: c.cbz, epub: c.epub),
      ResourceType.cbz => (dir: c.dir, zip: c.zip, cbz: c.cbz + 1, epub: c.epub),
      ResourceType.epub => (dir: c.dir, zip: c.zip, cbz: c.cbz, epub: c.epub + 1),
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
      ));

      final historyRepo = _ref.read(readingHistoryRepoProvider);
      final seriesRepo = _ref.read(librarySeriesRepoProvider);
      final sessionRepo = _ref.read(readingSessionRepoProvider);

      await historyRepo.deleteByComicIds(ids);
      await seriesRepo.removeComicsFromSeries(ids);
      await sessionRepo.deleteSessionsByComicIds(ids);

      emit((
        phase: SyncLibraryPhase.writingDb,
        route: SyncLibraryRoute.noRootsCleared,
        currentPath: null,
        acceptedTotal: 0,
        counts: emptyLibrarySyncCounts(),
      ));

      await repo.deleteByIds(ids);

      emit((
        phase: SyncLibraryPhase.done,
        route: SyncLibraryRoute.noRootsCleared,
        currentPath: null,
        acceptedTotal: 0,
        counts: emptyLibrarySyncCounts(),
      ));
      return;
    }

    final scanner = _ref.read(resourceScannerProvider);
    final parser = _ref.read(resourceParserProvider);
    final mapper = _ref.read(libraryComicMapperProvider);
    final repo = _ref.read(libraryComicRepoProvider);

    final candidates = scanner.scanRoots(
      effectiveRoots,
      isCancelled: isCancelled,
    );

    var counts = emptyLibrarySyncCounts();
    var acceptedTotal = 0;
    final comics = <LibraryComic>[];

    await for (final c in candidates) {
      if (isCancelled?.call() == true) {
        return;
      }

      emit((
        phase: SyncLibraryPhase.scanning,
        route: SyncLibraryRoute.withRoots,
        currentPath: c.path,
        acceptedTotal: acceptedTotal,
        counts: counts,
      ));

      final p = await parser.parse(c);
      if (p != null) {
        counts = _bump(counts, p.type);
        acceptedTotal++;
        comics.add(mapper.fromParsedResource(p));
        emit((
          phase: SyncLibraryPhase.scanning,
          route: SyncLibraryRoute.withRoots,
          currentPath: c.path,
          acceptedTotal: acceptedTotal,
          counts: counts,
        ));
      }
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
    ));

    await repo.replaceByScan(List<LibraryComic>.from(comics));

    emit((
      phase: SyncLibraryPhase.done,
      route: SyncLibraryRoute.withRoots,
      currentPath: null,
      acceptedTotal: acceptedTotal,
      counts: counts,
    ));
  }
}
