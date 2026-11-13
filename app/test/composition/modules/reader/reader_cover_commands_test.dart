import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/composition/overrides/comic_series_shared_state_overrides.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_repository_providers.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_cover_editor_notifier.dart';
import 'package:hentai_library/features/series/presentation/providers/series_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/shared/presentation/providers/cover_command_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_slot_providers.dart';
import 'package:test/test.dart';

const _comic = ReaderComicRef(
  comicId: 'comic-1',
  path: '/library/comic-1.zip',
  resourceType: ResourceType.zip,
  title: 'Comic',
  pageCount: 10,
);

void main() {
  test('composition is inert until a Reader command writes and refreshes the cache', () async {
    final repository = _Repository();
    final container = _container(repository);
    container.read(setComicCoverFromPageCommandProvider);
    container.read(setSeriesCoverFromPageCommandProvider);
    final editor = container.read(readerCoverEditorProvider.notifier);
    expect(repository.events, isEmpty);
    await editor.setComicCover(_comic, pageIndex: 4);
    expect(repository.events, [
      'comic:comic-1:/library/comic-1.zip:zip:4',
      'read:comic-1',
    ]);
    expect(
      container.read(comicCoverThumbnailCacheProvider('comic-1')),
      same(repository.stored),
    );
  });

  for (final bytes in <Uint8List?>[null, Uint8List(0)]) {
    test(
      'a missing or empty thumbnail keeps the previously displayed cache: $bytes',
      () async {
        final repository = _Repository()..stored = bytes;
        final container = _container(repository);
        final cached = Uint8List.fromList([9]);
        container
            .read(comicCoverThumbnailCacheProvider('comic-1').notifier)
            .set(cached);
        await container
            .read(readerCoverEditorProvider.notifier)
            .setComicCover(_comic, pageIndex: 0);
        expect(repository.events, [
          'comic:comic-1:/library/comic-1.zip:zip:0',
          'read:comic-1',
        ]);
        expect(
          container.read(comicCoverThumbnailCacheProvider('comic-1')),
          same(cached),
        );
      },
    );
  }

  for (final failOnRead in [false, true]) {
    test(
      'comic failure preserves cache and does not repeat the committed write, read=$failOnRead',
      () async {
        final failure = StateError('cover');
        final repository = _Repository();
        if (failOnRead) {
          repository.readFailure = failure;
        } else {
          repository.writeFailure = failure;
        }
        final container = _container(repository);
        final cached = Uint8List.fromList([9]);
        container
            .read(comicCoverThumbnailCacheProvider('comic-1').notifier)
            .set(cached);
        await expectLater(
          container
              .read(readerCoverEditorProvider.notifier)
              .setComicCover(_comic, pageIndex: 4),
          throwsA(same(failure)),
        );
        expect(repository.events, [
          'comic:comic-1:/library/comic-1.zip:zip:4',
          if (failOnRead) 'read:comic-1',
        ]);
        expect(
          container.read(comicCoverThumbnailCacheProvider('comic-1')),
          same(cached),
        );
      },
    );
  }

  test('the composed Series command invalidates the actual source only after the write completes', () async {
    final repository = _Repository();
    final response = Completer<void>();
    repository.seriesWrite = () => response.future;
    final container = _container(repository);
    final source = seriesCoverSourceProvider('series-1');
    final listener = container.listen(source, (_, _) {});
    addTearDown(listener.close);
    await container.read(source.future);
    final pending = container
        .read(readerCoverEditorProvider.notifier)
        .setSeriesCover('series-1', _comic, pageIndex: 2);
    expect(repository.events, [
      'resolve:series-1',
      'series:series-1:comic-1:/library/comic-1.zip:zip:2',
    ]);
    response.complete();
    await pending;
    await container.read(source.future);
    expect(repository.events, [
      'resolve:series-1',
      'series:series-1:comic-1:/library/comic-1.zip:zip:2',
      'resolve:series-1',
    ]);
  });

  test(
    'Series write failure leaves the actual source valid without retry',
    () async {
      final repository = _Repository();
      final failure = StateError('series write');
      repository.writeFailure = failure;
      final container = _container(repository);
      final source = seriesCoverSourceProvider('series-1');
      final listener = container.listen(source, (_, _) {});
      addTearDown(listener.close);
      await container.read(source.future);
      await expectLater(
        container
            .read(readerCoverEditorProvider.notifier)
            .setSeriesCover('series-1', _comic, pageIndex: 2),
        throwsA(same(failure)),
      );
      await container.read(source.future);
      expect(repository.events, [
        'resolve:series-1',
        'series:series-1:comic-1:/library/comic-1.zip:zip:2',
      ]);
    },
  );

  test('owner invalidation failure propagates after one Series write without compensation', () async {
    final repository = _Repository();
    final failure = StateError('series invalidation');
    final container = ProviderContainer(
      overrides: [
        comicThumbnailRepoProvider.overrideWithValue(repository),
        seriesCoverInvalidationSlotProvider.overrideWithValue((id) {
          repository.events.add('invalidate:$id');
          throw failure;
        }),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(seriesCoverSetCommandProvider)(
        seriesId: 'series-1',
        comicId: _comic.comicId,
        path: _comic.path,
        resourceType: _comic.resourceType,
        pageIndex: 2,
      ),
      throwsA(same(failure)),
    );
    expect(repository.events, [
      'series:series-1:comic-1:/library/comic-1.zip:zip:2',
      'invalidate:series-1',
    ]);
  });
}

ProviderContainer _container(_Repository repository) {
  final container = ProviderContainer(
    overrides: [
      ...comicSeriesSharedStateOverrides(),
      comicThumbnailRepoProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _Repository implements ComicThumbnailRepository {
  final events = <String>[];
  Uint8List? stored = Uint8List.fromList([1, 2, 3]);
  Object? writeFailure;
  Object? readFailure;
  Future<void> Function()? seriesWrite;

  @override
  Future<void> setComicCoverFromPage({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int pageIndex,
  }) async {
    events.add('comic:$comicId:$path:${resourceType.name}:$pageIndex');
    if (writeFailure case final failure?) throw failure;
  }

  @override
  Future<ComicThumbnailRecord?> findByComicId(String comicId) async {
    events.add('read:$comicId');
    if (readFailure case final failure?) throw failure;
    final bytes = stored;
    return bytes == null
        ? null
        : (
            thumbnail: bytes,
            sourceModifiedMs: 0,
            sourceSize: 0,
            isUserSet: true,
          );
  }

  @override
  Future<void> setSeriesCoverFromPage({
    required String seriesId,
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int pageIndex,
  }) async {
    events.add(
      'series:$seriesId:$comicId:$path:${resourceType.name}:$pageIndex',
    );
    if (writeFailure case final failure?) throw failure;
    await seriesWrite?.call();
  }

  @override
  Future<SeriesCoverSource> resolveSeriesCover(String seriesId) async {
    events.add('resolve:$seriesId');
    return const SeriesCoverMissing();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
