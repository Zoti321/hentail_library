import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_cover_providers.dart';
import 'package:hentai_library/features/comic_trash/application/comic_trash_service.dart';
import 'package:hentai_library/features/comic_trash/presentation/providers/comic_trash_use_case_provider.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/comic_trash_actions.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:hentai_library/shared/application/errors/app_exception.dart';

void main() {
  late _Service service;
  late _Cache cache;

  ProviderContainer createContainer({bool busy = false}) {
    service = _Service();
    cache = _Cache();
    final container = ProviderContainer(
      overrides: [
        comicTrashServiceProvider.overrideWithValue(service),
        libraryMutationBusyStateProvider.overrideWithValue(busy),
        comicCoverCacheManagerProvider.overrideWith(() => cache),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'purge returns original summary and clears only reconciled removed covers',
    () async {
      final container = createContainer();
      final result = await container
          .read(comicTrashActionsProvider.notifier)
          .purge(['removed', 'failed']);
      expect(result, service.outcome.result);
      expect(service.calls, ['purge']);
      expect(cache.cleared, ['removed']);
    },
  );

  test(
    'purgeAll delegates target selection to the application service',
    () async {
      final container = createContainer();
      final result = await container
          .read(comicTrashActionsProvider.notifier)
          .purgeAll();
      expect(result, service.outcome.result);
      expect(service.calls, ['all']);
      expect(cache.cleared, ['removed']);
    },
  );

  test('busy guard prevents target reads and purge calls', () async {
    final container = createContainer(busy: true);
    final actions = container.read(comicTrashActionsProvider.notifier);
    await expectLater(actions.purgeAll(), throwsA(isA<AppException>()));
    await expectLater(actions.purge(['c1']), throwsA(isA<AppException>()));
    expect(service.calls, isEmpty);
    expect(cache.cleared, isEmpty);
  });

  test('application failure leaves caches intact', () async {
    final container = createContainer();
    service.fail = true;
    await expectLater(
      container.read(comicTrashActionsProvider.notifier).purgeAll(),
      throwsStateError,
    );
    expect(cache.cleared, isEmpty);
    expect(service.calls, ['all']);
  });
}

class _Service implements ComicTrashService {
  final calls = <String>[];
  bool fail = false;
  final ComicPurgeOutcome outcome = (
    result: (succeeded: 1, failed: 1, errorSamples: ['failed']),
    purgedIds: ['removed'],
  );
  @override
  Future<ComicPurgeOutcome> purgeComics(Iterable<String> comicIds) async {
    calls.add('purge');
    if (fail) throw StateError('reconciliation');
    return outcome;
  }

  @override
  Future<ComicPurgeOutcome> purgeAll() async {
    calls.add('all');
    if (fail) throw StateError('reconciliation');
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cache extends ComicCoverCacheManager {
  final cleared = <String>[];
  @override
  void clearForComics(Iterable<String> comicIds) => cleared.addAll(comicIds);
}
