import 'dart:typed_data';

import 'package:hentai_library/features/comic/presentation/providers/comic_cover_providers.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_cover_editor_notifier.dart';
import 'package:hentai_library/shared/presentation/providers/series_slot_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:hentai_library/features/comic/public/providers/comic_repository_providers.dart';

class _RecordingThumbnailRepository implements ComicThumbnailRepository {
  final List<String> calls = <String>[];
  Uint8List stored = Uint8List(0);

  @override
  Future<void> setComicCoverFromPage({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int pageIndex,
  }) async {
    calls.add('comic:$comicId:${resourceType.name}:$pageIndex');
    stored = Uint8List.fromList(<int>[1, 2, 3]);
  }

  @override
  Future<void> setSeriesCoverFromPage({
    required String seriesId,
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int pageIndex,
  }) async {
    calls.add('series:$seriesId:$comicId:$pageIndex');
  }

  @override
  Future<ComicThumbnailRecord?> findByComicId(String comicId) async =>
      (thumbnail: stored, sourceModifiedMs: 0, sourceSize: 0, isUserSet: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReaderComicRef _comic() {
  return const ReaderComicRef(
    comicId: 'comic-1',
    path: '/library/comic-1.zip',
    resourceType: ResourceType.zip,
    title: 'Comic',
    pageCount: 10,
  );
}

void main() {
  late _RecordingThumbnailRepository repo;
  late List<String> invalidatedSeries;
  late ProviderContainer container;

  setUp(() {
    repo = _RecordingThumbnailRepository();
    invalidatedSeries = <String>[];
    container = ProviderContainer(
      overrides: <Override>[
        comicThumbnailRepoProvider.overrideWithValue(repo),
        seriesCoverInvalidationSlotProvider.overrideWithValue(
          (String seriesId) => invalidatedSeries.add(seriesId),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  ReaderCoverEditorNotifier editor() =>
      container.read(readerCoverEditorProvider.notifier);

  test('setComicCover writes the page and caches the new thumbnail', () async {
    await editor().setComicCover(_comic(), pageIndex: 4);

    expect(repo.calls, <String>['comic:comic-1:zip:4']);
    expect(container.read(comicCoverThumbnailCacheProvider('comic-1')), <int>[
      1,
      2,
      3,
    ]);
  });

  test('setSeriesCover writes the page for the series', () async {
    await editor().setSeriesCover('series-1', _comic(), pageIndex: 2);

    expect(repo.calls, <String>['series:series-1:comic-1:2']);
    expect(invalidatedSeries, <String>['series-1']);
  });
}
