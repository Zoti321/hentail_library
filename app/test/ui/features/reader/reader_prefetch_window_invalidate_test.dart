import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/domain/reading/reader_session_service.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test(
    'warmWindow invalidates keepAlive pages that left the prefetch window',
    () async {
      const String comicId = 'prefetch-invalidate-comic';
      final Map<int, int> loads = <int, int>{};

      final Comic comic = Comic(
        comicId: comicId,
        path: '/tmp/test.cbz',
        resourceType: ResourceType.cbz,
        resourceSize: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        lastUpdatedAt: DateTime.utc(2026, 1, 1),
        title: 'Invalidate',
        pageCount: 40,
      );

      final ReaderSessionService session = ReaderSessionService(
        comicRepo: _FakeComicRepo(comic),
        pageSource: _FakePageSource(loads),
        readingHistoryRepo: _FakeHistoryRepo(),
        sessionPort: _FakeSessionPort(),
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          readerSessionServiceProvider.overrideWithValue(session),
          ...List<Override>.generate(40, (int index) {
            return comicReaderPageProvider(
              comicId: comicId,
              pageIndex: index,
            ).overrideWith((Ref ref) async {
              loads[index] = (loads[index] ?? 0) + 1;
              return ReaderPageBytes(Uint8List(0));
            });
          }),
        ],
      );
      addTearDown(container.dispose);

      // Prime keepAlive for early pages.
      await container.read(
        comicReaderPageProvider(comicId: comicId, pageIndex: 0).future,
      );
      await container.read(
        comicReaderPageProvider(comicId: comicId, pageIndex: 1).future,
      );
      expect(loads[0], 1);
      expect(loads[1], 1);

      final ReaderPrefetchController prefetch = container.read(
        readerPrefetchControllerProvider.notifier,
      );

      await prefetch.warmWindow(
        comicId: comicId,
        centerPageOneBased: 1,
        totalPages: 40,
      );
      await prefetch.warmWindow(
        comicId: comicId,
        centerPageOneBased: 28,
        totalPages: 40,
      );

      // Pages 1–3 left the window and must be invalidated (reload on next read).
      await container.read(
        comicReaderPageProvider(comicId: comicId, pageIndex: 0).future,
      );
      expect(
        loads[0],
        greaterThan(1),
        reason: 'page 1 must reload after leaving prefetch window',
      );
    },
  );
}

class _FakeComicRepo implements ComicRepository {
  _FakeComicRepo(this.comic);
  final Comic comic;

  @override
  Future<Comic?> findById(String comicId) async => comic;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHistoryRepo implements ReadingHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSessionPort implements ReaderSessionPort {
  @override
  Future<void> openComic(Comic comic) async {}

  @override
  Future<void> closeComic(String comicId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePageSource implements ComicPageSourcePort {
  _FakePageSource(this.loads);
  final Map<int, int> loads;

  @override
  Future<List<ReadSessionPage>> loadPages(Comic comic) async {
    return List<ReadSessionPage>.generate(
      40,
      (int i) => ReadSessionArchivePage(comicId: comic.comicId, pageIndex: i),
    );
  }

  @override
  Future<ReaderPagePayload> loadReaderPage({
    required Comic comic,
    required int pageIndex,
  }) async {
    loads[pageIndex] = (loads[pageIndex] ?? 0) + 1;
    return ReaderPageBytes(Uint8List(0));
  }

  @override
  Future<void> prefetchPages({
    required Comic comic,
    required List<int> pageIndexes,
    required int generation,
  }) async {}

  @override
  Future<void> clearPageCache({required String comicId}) async {}

  @override
  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  }) async => null;
}
