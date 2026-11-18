import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/presentation/image/reader_image_cache.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_prefetch_notifier.dart';

class _Service implements OpenReadSessionUseCase {
  final requests = <({String comicId, int generation, List<int> pages})>[];
  final pending = <Future<void>>[];
  final cleared = <String>[];

  @override
  Future<void> prefetchPages({
    required String sessionKey,
    required List<int> archivePageIndexes,
    required int generation,
  }) async {
    requests.add((
      comicId: sessionKey,
      generation: generation,
      pages: archivePageIndexes,
    ));
    if (pending.isNotEmpty) await pending.removeAt(0);
  }

  @override
  Future<ReaderPagePayload> loadReaderPage({
    required String sessionKey,
    required int archivePageIndex,
  }) async => ReaderPageBytes(Uint8List.fromList([archivePageIndex]));

  @override
  Future<void> clearPageCache({required String sessionKey}) async {
    cleared.add(sessionKey);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Service service;
  late ProviderContainer container;
  var disposed = false;
  final images = List<ReaderPageImageData>.generate(
    20,
    (index) => ReaderDirPageImageData(
      File('/virtual/reader-page-$index'),
      pageIndex: index,
    ),
  );
  setUp(() {
    disposed = false;
    service = _Service();
    container = ProviderContainer(
      overrides: [openReadSessionUseCaseProvider.overrideWithValue(service)],
    );
    addTearDown(() {
      if (!disposed) container.dispose();
      clearReaderPathBytes();
    });
  });
  ReaderPrefetchNotifier controller() =>
      container.read(readerPrefetchNotifierProvider.notifier);
  Future<bool> warm(int center, {String comicId = 'comic'}) =>
      controller().warmWindow(
        comicId: comicId,
        centerPageOneBased: center,
        totalPages: 20,
        imageList: images,
      );

  test(
    'precache stops after the UI unmounts during a pending decode',
    () async {
      await warm(1);
      final decoded = <ReaderPagePayload>[];
      final pending = Completer<void>();
      var mounted = true;
      final result = controller().precacheWindow(
        isMounted: () => mounted,
        precachePage: (page, width) {
          decoded.add(page);
          expect(width, 320);
          return pending.future;
        },
        comicId: 'comic',
        pageIndexesOneBased: {1, 2},
        imageList: images,
        cacheWidth: 320,
      );
      expect(decoded, hasLength(1));
      mounted = false;
      pending.complete();
      await result;
      expect(decoded, hasLength(1));
    },
  );

  test('precache visits each page while the UI remains mounted', () async {
    await warm(1);
    final decoded = <ReaderPagePayload>[];
    await controller().precacheWindow(
      isMounted: () => true,
      precachePage: (page, _) async => decoded.add(page),
      comicId: 'comic',
      pageIndexesOneBased: {1, 2},
      imageList: images,
    );
    expect(decoded.whereType<ReaderPageFilePath>().map((page) => page.path), [
      images[0] is ReaderDirPageImageData
          ? (images[0] as ReaderDirPageImageData).file.path
          : '',
      (images[1] as ReaderDirPageImageData).file.path,
    ]);
  });

  for (final clear in [false, true]) {
    test(
      'old window cannot evict a replacement cache, cleared: $clear',
      () async {
        final pending = Completer<void>();
        service.pending.add(pending.future);
        final old = warm(1);
        final oldGeneration = service.requests.single.generation;
        if (clear) controller().clearComic('comic');
        expect(await warm(10), isTrue);
        final newGeneration = service.requests.last.generation;
        final bytes = Uint8List.fromList([42]);
        putReaderPathBytes('/virtual/reader-page-9', bytes);
        pending.complete();
        final changed = await old;
        expect(peekReaderPathBytes('/virtual/reader-page-9'), same(bytes));
        expect(changed, isFalse);
        expect(newGeneration, greaterThan(oldGeneration));
      },
    );
  }

  test(
    'clearing and reopening the same window never reuses a generation',
    () async {
      final pending = Completer<void>();
      service.pending.add(pending.future);
      final old = warm(1);
      final previous = service.requests.single.generation;
      controller().clearComic('comic');
      expect(await warm(1), isTrue);
      pending.complete();
      expect(await old, isFalse);
      expect(service.requests.last.generation, greaterThan(previous));
    },
  );

  test(
    'a disposed window completes without accessing its released provider',
    () async {
      final pending = Completer<void>();
      service.pending.add(pending.future);
      final old = warm(1);
      container.dispose();
      disposed = true;
      pending.complete();
      expect(await old, isFalse);
    },
  );

  test(
    'rebuild permits the same window and invalidates the old continuation',
    () async {
      final pending = Completer<void>();
      service.pending.add(pending.future);
      final old = warm(1);
      container.invalidate(readerPrefetchNotifierProvider);
      expect(await warm(1), isTrue);
      pending.complete();
      expect(await old, isFalse);
      expect(service.requests, hasLength(2));
    },
  );

  test(
    'current cleanup removes only touched pages outside the current window',
    () async {
      final pending = Completer<void>();
      service.pending.add(pending.future);
      final warming = warm(1);
      controller().notePageTouched(comicId: 'comic', pageOneBased: 15);
      final outside = Uint8List.fromList([15]);
      final inside = Uint8List.fromList([1]);
      putReaderPathBytes('/virtual/reader-page-14', outside);
      putReaderPathBytes('/virtual/reader-page-0', inside);
      pending.complete();
      expect(await warming, isTrue);
      expect(peekReaderPathBytes('/virtual/reader-page-14'), isNull);
      expect(peekReaderPathBytes('/virtual/reader-page-0'), same(inside));
      expect(await warm(1), isFalse);
      expect(service.requests, hasLength(1));
    },
  );

  test(
    'another Comic window does not cancel this Comic continuation',
    () async {
      final pending = Completer<void>();
      service.pending.add(pending.future);
      final first = warm(1);
      expect(await warm(10, comicId: 'other'), isTrue);
      pending.complete();
      expect(await first, isTrue);
    },
  );

  test('prefetch failure retains the original error without retry', () async {
    final pending = Completer<void>();
    service.pending.add(pending.future);
    final result = warm(1);
    final error = StateError('prefetch');
    final checked = expectLater(result, throwsA(same(error)));
    pending.completeError(error);
    await checked;
    expect(service.requests, hasLength(1));
  });
}
