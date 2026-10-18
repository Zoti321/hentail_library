import 'dart:async';

import 'package:hentai_library/features/library_admin/di/library_sync.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/shared/domain/library/sync_library_port.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _ScriptedSyncAdapter implements SyncLibraryPort {
  _ScriptedSyncAdapter(this._run);

  final Future<void> Function({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  })
  _run;

  @override
  void cancelActive() {}

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

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  _FakeLibraryRevisionPort(this._events);

  final StreamController<void> _events;

  @override
  Stream<void> watchRevision() => _events.stream;
}

void main() {
  test('start bumps library revision after successful sync', () async {
    final StreamController<void> events = StreamController<void>.broadcast();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        syncLibraryPortProvider.overrideWithValue(
          _ScriptedSyncAdapter(({required isCancelled, onProgress}) async {}),
        ),
        libraryRevisionPortProvider.overrideWithValue(
          _FakeLibraryRevisionPort(events),
        ),
      ],
    );
    addTearDown(container.dispose);

    final int revisionBefore =
        container.read(libraryRevisionProvider).revision;
    await container
        .read(scanLibraryControllerProvider.notifier)
        .start(promptStorageAccess: false);
    final int revisionAfter = container.read(libraryRevisionProvider).revision;

    expect(revisionAfter, greaterThan(revisionBefore));
  });

  test('cancel before sync completes does not bump revision', () async {
    final StreamController<void> events = StreamController<void>.broadcast();
    late ScanLibraryController controller;
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        syncLibraryPortProvider.overrideWithValue(
          _ScriptedSyncAdapter(({required isCancelled, onProgress}) async {
            controller.cancel();
          }),
        ),
        libraryRevisionPortProvider.overrideWithValue(
          _FakeLibraryRevisionPort(events),
        ),
      ],
    );
    addTearDown(container.dispose);
    controller = container.read(scanLibraryControllerProvider.notifier);

    final int revisionBefore =
        container.read(libraryRevisionProvider).revision;
    await controller.start(promptStorageAccess: false);
    final int revisionAfter = container.read(libraryRevisionProvider).revision;

    expect(revisionAfter, revisionBefore);
  });
}
