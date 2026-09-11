import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/domain/thumbnail/thumbnail_event.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/providers/comic_cover_load_gate.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

void main() {
  late _FakeComicRepo comicRepo;
  late _FakeThumbnailRepo thumbnailRepo;
  late ProviderContainer container;
  late List<Completer<void>> gateBlockers;

  setUp(() {
    comicRepo = _FakeComicRepo();
    thumbnailRepo = _FakeThumbnailRepo();
    container = ProviderContainer(
      overrides: <Override>[
        comicRepoProvider.overrideWith((Ref ref) => comicRepo),
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
  });

  test(
    'dispose while queued on load gate skips work and does not log SEVERE',
    () async {
      gateBlockers = List<Completer<void>>.generate(
        ComicCoverLoadGate.maxConcurrent,
        (_) => Completer<void>(),
      );
      for (final Completer<void> blocker in gateBlockers) {
        unawaited(ComicCoverLoadGate.run(() => blocker.future));
      }

      final List<LogRecord> severeRecords = <LogRecord>[];
      final StreamSubscription<LogRecord> logSub =
          Logger('hentai.ui.comic_cover').onRecord.listen((LogRecord record) {
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
      expect(comicRepo.findByIdCalls, isEmpty);

      coverSub.close();
      await Future<void>.delayed(Duration.zero);

      for (final Completer<void> blocker in gateBlockers) {
        blocker.complete();
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(comicRepo.findByIdCalls, isEmpty);
      expect(severeRecords, isEmpty);

      await logSub.cancel();
    },
  );

  test('loads NoCover when comic is missing', () async {
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
    expect(comicRepo.findByIdCalls, <String>['missing']);

    coverSub.close();
  });
}

class _FakeComicRepo implements ComicRepository {
  final List<String> findByIdCalls = <String>[];

  @override
  Future<Comic?> findById(String comicId) async {
    findByIdCalls.add(comicId);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThumbnailRepo implements ComicThumbnailRepository {
  @override
  Future<ComicThumbnailRecord?> findByComicId(String comicId) async => null;

  @override
  Future<ComicThumbnailRecord?> ensureByComicId({
    required String comicId,
    required ThumbnailPriority priority,
  }) async => null;

  @override
  Stream<ThumbnailEvent> watchEvents() => const Stream<ThumbnailEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
