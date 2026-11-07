import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/di/comic_cover_load_gate.dart';
import 'package:hentai_library/features/comic/di/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/domain/comic_thumbnail_repository.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/thumbnail/thumbnail_event.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

void main() {
  late _FakeThumbnailRepo thumbnailRepo;
  late ProviderContainer container;
  late List<Completer<void>> gateBlockers;

  setUp(() {
    ComicCoverLoadGate.debugReset();
    thumbnailRepo = _FakeThumbnailRepo();
    container = ProviderContainer(
      overrides: <Override>[
        comicThumbnailRepoProvider.overrideWith((Ref ref) => thumbnailRepo),
      ],
    );
    gateBlockers = <Completer<void>>[];
  });

  tearDown(() async {
    for (final Completer<void> blocker in gateBlockers) {
      if (!blocker.isCompleted) {
        blocker.complete();
      }
    }
    // Drain any queued gate work before the next test.
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    ComicCoverLoadGate.debugReset();
  });

  test('dispose while queued on load gate skips work and does not log SEVERE', () async {
    gateBlockers = List<Completer<void>>.generate(
      ComicCoverLoadGate.maxConcurrent,
      (_) => Completer<void>(),
    );
    for (final Completer<void> blocker in gateBlockers) {
      unawaited(ComicCoverLoadGate.run(() => blocker.future));
    }

    final List<LogRecord> severeRecords = <LogRecord>[];
    final StreamSubscription<LogRecord> logSub = Logger('hentai.ui.comic_cover')
        .onRecord
        .listen((LogRecord record) {
          if (record.level >= Level.SEVERE) {
            severeRecords.add(record);
          }
        });

    final ProviderSubscription<ComicCoverState> coverSub = container.listen(
      comicCoverProvider('comic-1'),
      (_, _) {},
    );
    // build schedules ensureLoaded via microtask; let it queue behind the gate.
    await Future<void>.delayed(Duration.zero);
    expect(thumbnailRepo.ensureCalls, isEmpty);

    coverSub.close();
    await Future<void>.delayed(Duration.zero);

    for (final Completer<void> blocker in gateBlockers) {
      blocker.complete();
    }
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(thumbnailRepo.ensureCalls, isEmpty);
    expect(severeRecords, isEmpty);

    await logSub.cancel();
  });

  test('loads NoCover when ensure returns null', () async {
    final ProviderSubscription<ComicCoverState> coverSub = container.listen(
      comicCoverProvider('missing'),
      (_, _) {},
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(comicCoverProvider('missing')),
      isA<ComicCoverNoCover>(),
    );
    expect(thumbnailRepo.ensureCalls, <String>['missing']);

    coverSub.close();
  });

  test('thumbnail cache LRU evicts oldest keep-alive bytes', () async {
    final ProviderSubscription<void> lruSub = container.listen(
      comicCoverThumbnailLruProvider,
      (_, _) {},
    );

    for (int i = 0; i < kComicCoverThumbnailCacheMaxEntries + 5; i++) {
      container
          .read(comicCoverThumbnailCacheProvider('c$i').notifier)
          .set(Uint8List.fromList(<int>[i & 0xff]));
    }

    expect(
      container.read(comicCoverThumbnailCacheProvider('c0')),
      isNull,
    );
    expect(
      container.read(
        comicCoverThumbnailCacheProvider(
          'c${kComicCoverThumbnailCacheMaxEntries + 4}',
        ),
      ),
      isNotNull,
    );

    lruSub.close();
  });
}

class _FakeThumbnailRepo implements ComicThumbnailRepository {
  final List<String> ensureCalls = <String>[];

  @override
  Future<ComicThumbnailRecord?> findByComicId(String comicId) async => null;

  @override
  Future<ComicThumbnailRecord?> ensureByComicId({
    required String comicId,
    required ThumbnailPriority priority,
  }) async {
    ensureCalls.add(comicId);
    return null;
  }

  @override
  Stream<ThumbnailEvent> watchEvents() => const Stream<ThumbnailEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
