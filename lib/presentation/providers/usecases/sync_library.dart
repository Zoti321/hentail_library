import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/usecases/usecases.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
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

  Future<void> call({bool Function()? isCancelled}) async {
    // 1. 通过path仓储获取所有选中的路径
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
        return;
      }

      final ids = existing.map((e) => e.comicId).toList();

      final historyRepo = _ref.read(readingHistoryRepoProvider);
      final seriesRepo = _ref.read(librarySeriesRepoProvider);
      final sessionRepo = _ref.read(readingSessionRepoProvider);

      await historyRepo.deleteByComicIds(ids);
      await seriesRepo.removeComicsFromSeries(ids);
      await sessionRepo.deleteSessionsByComicIds(ids);
      await repo.deleteByIds(ids);
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
    final parsed = parser.parseAll(candidates);
    final comics = <LibraryComic>[];

    await for (final p in parsed) {
      if (isCancelled?.call() == true) {
        return;
      }
      comics.add(mapper.fromParsedResource(p));
    }

    await repo.replaceByScan(List<LibraryComic>.from(comics));
  }
}
