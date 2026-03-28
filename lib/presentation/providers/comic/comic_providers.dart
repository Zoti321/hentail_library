import 'package:hentai_library/domain/entity/comic/library_tag.dart' as v2;
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/usecases/usecases.dart';
import 'package:hentai_library/domain/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/value_objects/sync_report/scanned_item_report.dart';
import 'package:hentai_library/domain/value_objects/sync_report/sync_progress.dart';
import 'package:hentai_library/domain/value_objects/sync_report/sync_report.dart';
import 'package:hentai_library/presentation/providers/v2/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_providers.g.dart';

@Riverpod(keepAlive: true)
SyncComicsUseCase syncComicsUseCase(Ref ref) => SyncComicsUseCase(ref);

@Riverpod(keepAlive: true)
UpdateComicMetadataFacadeUseCase updateComicMetadataUseCase(Ref ref) =>
    UpdateComicMetadataFacadeUseCase(ref);

@Riverpod(keepAlive: true)
RecordReadingProgressUseCase recordReadingProgressUseCase(Ref ref) {
  return RecordReadingProgressUseCase(ref.read(readingHistoryRepoProvider));
}

/// 扫描漫画库是否进行中。用于单例约束：扫描中不允许再打开新扫描对话框。
@Riverpod(keepAlive: true)
class ScanInProgressNotifier extends _$ScanInProgressNotifier {
  @override
  bool build() => false;

  void setInProgress(bool value) => state = value;
}

class SyncComicsUseCase {
  final Ref _ref;

  SyncComicsUseCase(this._ref);

  Future<SyncReport?> call({
    bool Function()? isCancelled,
    void Function(SyncProgress)? onProgress,
  }) async {
    final dirs = await _ref.read(pathRepoProvider).getAll();
    onProgress?.call(
      const SyncProgress(
        phase: SyncPhase.collecting,
        message: 'v2: collecting roots',
      ),
    );

    final scanner = _ref.read(resourceScannerProvider);
    final parser = _ref.read(resourceParserProvider);
    final mapper = _ref.read(libraryComicMapperProvider);
    final repo = _ref.read(libraryComicRepoProvider);

    final candidates = scanner.scanRoots(dirs, isCancelled: isCancelled);
    final parsed = parser.parseAll(candidates);
    final items = <ScannedItemReport>[];
    final comics = <dynamic>[];
    var count = 0;

    await for (final p in parsed) {
      if (isCancelled?.call() == true) {
        return const SyncReport(
          scannedItems: [],
          addedCount: 0,
          removedCount: 0,
          cancelled: true,
        );
      }
      count++;
      onProgress?.call(
        SyncProgress(
          phase: SyncPhase.scanning,
          currentPath: p.path,
          current: count,
          total: 0,
          message: 'v2: parsing',
        ),
      );
      comics.add(mapper.fromParsedResource(p));
      items.add(
        ScannedItemReport(
          path: p.path,
          type: switch (p.type.name) {
            'dir' => ScannedItemType.folder,
            'epub' => ScannedItemType.epub,
            _ => ScannedItemType.archive,
          },
          title: p.meta.title,
        ),
      );
    }

    await repo.replaceByScan(List.from(comics));
    onProgress?.call(
      const SyncProgress(
        phase: SyncPhase.applying,
        message: 'v2: apply changes',
      ),
    );
    return SyncReport(
      scannedItems: items,
      addedCount: items.length,
      removedCount: 0,
    );
  }
}

class UpdateComicMetadataFacadeUseCase {
  final Ref _ref;

  UpdateComicMetadataFacadeUseCase(this._ref);

  Future<void> call(String comicId, ComicMetadataForm form) async {
    final useCase = _ref.read(updateLibraryComicMetaUseCaseProvider);
    final tags = form.tags.map((t) => v2.LibraryTag(name: t.name)).toList();
    await useCase.call(
      comicId,
      title: form.title,
      authors: form.authors,
      contentRating: form.isR18 ? ContentRating.r18 : ContentRating.safe,
      tags: tags,
    );
  }
}
