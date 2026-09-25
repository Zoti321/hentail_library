import 'dart:typed_data';

import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/ui/features/reader/view_models/reader_cover_editor_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _RecordingThumbnailRepository implements ComicThumbnailRepository {
  final List<String> calls = <String>[];
  Uint8List stored = Uint8List(0);

  @override
  Future<void> setComicCoverFromPage({
    required String comicId,
    required String path,
    required String resourceType,
    required int pageIndex,
  }) async {
    calls.add('comic:$comicId:$resourceType:$pageIndex');
    stored = Uint8List.fromList(<int>[1, 2, 3]);
  }

  @override
  Future<void> setSeriesCoverFromPage({
    required String seriesId,
    required String comicId,
    required String path,
    required String resourceType,
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

Comic _comic() {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return Comic(
    comicId: 'comic-1',
    path: '/library/comic-1.zip',
    resourceType: ResourceType.zip,
    resourceSize: 0,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Comic',
    contentRating: ContentRating.safe,
    authors: const [],
    tags: const [],
    languages: const [],
    parodies: const [],
    characters: const [],
    pageCount: 10,
  );
}

void main() {
  late _RecordingThumbnailRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _RecordingThumbnailRepository();
    container = ProviderContainer(
      overrides: <Override>[comicThumbnailRepoProvider.overrideWithValue(repo)],
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
  });
}
