import 'dart:async';

import 'package:hentai_library/features/library_admin/presentation/providers/library_sync_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_port.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';

class _ScriptedSyncAdapter implements SyncLibraryPort {
  _ScriptedSyncAdapter(this._run, {this.onCancel});

  final void Function()? onCancel;

  final Future<void> Function({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  })
  _run;

  @override
  void cancelActive() => onCancel?.call();

  @override
  Future<void> call({
    ScanMode scanMode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) {
    return _run(isCancelled: isCancelled, onProgress: onProgress);
  }
}

class _PendingRun {
  final Completer<void> completion = Completer<void>();
  late bool Function() isCancelled;
  void Function(SyncLibraryProgress)? onProgress;

  Future<void> call({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress)? onProgress,
  }) {
    this.isCancelled = isCancelled;
    this.onProgress = onProgress;
    return completion.future;
  }
}

SyncLibraryProgress _progress(String path) => (
  phase: SyncLibraryPhase.scanning,
  route: SyncLibraryRoute.withRoots,
  currentPath: path,
  acceptedTotal: 0,
  counts: emptyLibrarySyncCounts(),
  removedCount: null,
  addedCount: null,
  keptCount: null,
  migratedCount: null,
  thumbnailTotal: null,
  thumbnailDone: null,
  thumbnailFailedCount: null,
  errorMessage: null,
);

ProviderContainer _container(SyncLibraryPort port) {
  final container = ProviderContainer(
    overrides: [
      syncLibraryPortProvider.overrideWithValue(port),
      ...domainEventBusOverrides(),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'native cancel failure propagates while allowing an immediate restart',
    () async {
      final runs = [_PendingRun(), _PendingRun()];
      var next = 0;
      final failure = StateError('native cancel failed');
      final container = _container(
        _ScriptedSyncAdapter(
          ({required isCancelled, onProgress}) => runs[next++].call(
            isCancelled: isCancelled,
            onProgress: onProgress,
          ),
          onCancel: () => throw failure,
        ),
      );
      final controller = container.read(scanLibraryControllerProvider.notifier);
      final first = controller.start(promptStorageAccess: false);
      expect(controller.cancel, throwsA(same(failure)));
      final afterCancel = container.read(scanLibraryControllerProvider);
      final second = controller.start(promptStorageAccess: false);
      runs[0].completion.complete();
      await first;
      final afterFirst = container.read(scanLibraryControllerProvider);
      runs[1].completion.complete();
      await second;
      expect(afterCancel.running, isFalse);
      expect(afterCancel.cancelled, isTrue);
      expect(afterFirst.running, isTrue);
      expect(afterFirst.cancelled, isFalse);
      expect(next, 2);
    },
  );

  test('running notification reentry prevents the replaced run from requesting access', () async {
    final pending = _PendingRun();
    var accessRequests = 0;
    var portCalls = 0;
    final container = ProviderContainer(
      overrides: [
        syncLibraryPortProvider.overrideWithValue(
          _ScriptedSyncAdapter(({required isCancelled, onProgress}) {
            portCalls++;
            return pending.call(
              isCancelled: isCancelled,
              onProgress: onProgress,
            );
          }),
        ),
        localFilesystemAccessProvider.overrideWithValue(() async {
          accessRequests++;
        }),
        ...domainEventBusOverrides(),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(scanLibraryControllerProvider.notifier);
    var restarted = false;
    Future<void>? second;
    final subscription = container.listen(scanLibraryControllerProvider, (
      _,
      state,
    ) {
      if (state.running && !restarted) {
        restarted = true;
        controller.cancel();
        second = controller.start();
      }
    });
    addTearDown(subscription.close);
    final first = controller.start();
    await Future<void>.value();
    pending.completion.complete();
    await Future.wait([first, second!]);
    expect(accessRequests, 1);
    expect(portCalls, 1);
  });

  test(
    'disposed controller ignores late progress and asynchronous failure',
    () async {
      final pending = _PendingRun();
      final container = ProviderContainer(
        overrides: [
          syncLibraryPortProvider.overrideWithValue(
            _ScriptedSyncAdapter(pending.call),
          ),
          ...domainEventBusOverrides(),
        ],
      );
      final controller = container.read(scanLibraryControllerProvider.notifier);
      final run = controller.start(promptStorageAccess: false);
      container.dispose();
      Object? progressError;
      try {
        pending.onProgress!(_progress('late disposed'));
      } on Object catch (error) {
        progressError = error;
      }
      pending.completion.completeError(StateError('late disposed failure'));
      await run;
      expect(progressError, isNull);
    },
  );

  test('restart preserves cancellation of the previous run', () async {
    final runs = [_PendingRun(), _PendingRun()];
    var next = 0;
    final container = _container(
      _ScriptedSyncAdapter(
        ({required isCancelled, onProgress}) =>
            runs[next++].call(isCancelled: isCancelled, onProgress: onProgress),
      ),
    );
    final controller = container.read(scanLibraryControllerProvider.notifier);
    final first = controller.start(promptStorageAccess: false);
    controller.cancel();
    final second = controller.start(promptStorageAccess: false);
    final firstCancelled = runs[0].isCancelled();
    final secondCancelled = runs[1].isCancelled();
    runs[0].completion.complete();
    runs[1].completion.complete();
    await Future.wait([first, second]);
    expect(firstCancelled, isTrue);
    expect(secondCancelled, isFalse);
  });

  for (final fails in [false, true]) {
    test(
      'late ${fails ? 'failure' : 'completion'} cannot replace restarted run',
      () async {
        final runs = [_PendingRun(), _PendingRun()];
        var next = 0;
        final container = _container(
          _ScriptedSyncAdapter(
            ({required isCancelled, onProgress}) => runs[next++].call(
              isCancelled: isCancelled,
              onProgress: onProgress,
            ),
          ),
        );
        final controller = container.read(
          scanLibraryControllerProvider.notifier,
        );
        final revision = container.read(libraryRevisionProvider).revision;
        final first = controller.start(promptStorageAccess: false);
        controller.cancel();
        final second = controller.start(promptStorageAccess: false);
        runs[1].onProgress!(_progress('B'));
        runs[0].onProgress!(_progress('late A'));
        final afterLateProgress = container.read(scanLibraryControllerProvider);
        if (fails) {
          runs[0].completion.completeError(StateError('late A failure'));
        } else {
          runs[0].completion.complete();
        }
        await first;
        final afterFirst = container.read(scanLibraryControllerProvider);
        final revisionAfterFirst = container
            .read(libraryRevisionProvider)
            .revision;
        final repeatedStart = controller.start(promptStorageAccess: false);
        var idleCompleted = false;
        final idle = controller.waitUntilIdle().then(
          (_) => idleCompleted = true,
        );
        await Future<void>.value();
        final idleBeforeSecond = idleCompleted;
        runs[1].completion.complete();
        await Future.wait([second, repeatedStart, idle]);
        expect(afterLateProgress.progress?.currentPath, 'B');
        expect(afterFirst.running, isTrue);
        expect(afterFirst.cancelled, isFalse);
        expect(afterFirst.error, isNull);
        expect(afterFirst.progress?.currentPath, 'B');
        expect(revisionAfterFirst, revision);
        expect(identical(repeatedStart, second), isTrue);
        expect(idleBeforeSecond, isFalse);
        expect(container.read(scanLibraryControllerProvider).running, isFalse);
        expect(container.read(libraryRevisionProvider).revision, revision + 1);
        expect(next, 2);
      },
    );
  }

  test('synchronous progress reentry retains the restarted future', () async {
    final runs = [_PendingRun(), _PendingRun()];
    var next = 0;
    final container = _container(
      _ScriptedSyncAdapter(({required isCancelled, onProgress}) {
        final index = next++;
        final result = runs[index].call(
          isCancelled: isCancelled,
          onProgress: onProgress,
        );
        if (index == 0) onProgress!(_progress('A'));
        return result;
      }),
    );
    final controller = container.read(scanLibraryControllerProvider.notifier);
    Future<void>? second;
    var restarted = false;
    final subscription = container.listen(scanLibraryControllerProvider, (
      _,
      state,
    ) {
      if (state.progress?.currentPath == 'A' && !restarted) {
        restarted = true;
        controller.cancel();
        second = controller.start(promptStorageAccess: false);
      }
    });
    addTearDown(subscription.close);
    final first = controller.start(promptStorageAccess: false);
    final repeatedStart = controller.start(promptStorageAccess: false);
    runs[0].completion.complete();
    runs[1].completion.complete();
    await Future.wait([first, second!, repeatedStart]);
    expect(identical(repeatedStart, second), isTrue);
    expect(identical(first, second), isFalse);
    expect(next, 2);
  });

  test('start bumps library revision after successful sync', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        syncLibraryPortProvider.overrideWithValue(
          _ScriptedSyncAdapter(({required isCancelled, onProgress}) async {}),
        ),
        ...domainEventBusOverrides(),
      ],
    );
    addTearDown(container.dispose);

    final int revisionBefore = container.read(libraryRevisionProvider).revision;
    await container
        .read(scanLibraryControllerProvider.notifier)
        .start(promptStorageAccess: false);
    final int revisionAfter = container.read(libraryRevisionProvider).revision;

    expect(revisionAfter, greaterThan(revisionBefore));
  });

  test('cancel before sync completes does not bump revision', () async {
    late ScanLibraryController controller;
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        syncLibraryPortProvider.overrideWithValue(
          _ScriptedSyncAdapter(({required isCancelled, onProgress}) async {
            controller.cancel();
          }),
        ),
        ...domainEventBusOverrides(),
      ],
    );
    addTearDown(container.dispose);
    controller = container.read(scanLibraryControllerProvider.notifier);

    final int revisionBefore = container.read(libraryRevisionProvider).revision;
    await controller.start(promptStorageAccess: false);
    final int revisionAfter = container.read(libraryRevisionProvider).revision;

    expect(revisionAfter, revisionBefore);
  });
}
