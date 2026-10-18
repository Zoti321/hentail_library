import 'dart:async';

import 'package:hentai_library/features/library_admin/di/metadata_refresh.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/shared/domain/library/metadata_refresh_port.dart';
import 'package:hentai_library/shared/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _ScriptedRefreshAdapter implements MetadataRefreshPort {
  _ScriptedRefreshAdapter({
    this.onRefreshComic,
    this.onRefreshLibrary,
  });

  final Future<void> Function(String comicId)? onRefreshComic;
  final Future<MetadataRefreshBatchResult> Function(String libraryId)?
  onRefreshLibrary;

  @override
  Future<void> refreshComic(String comicId) {
    return onRefreshComic?.call(comicId) ?? Future<void>.value();
  }

  @override
  Future<MetadataRefreshBatchResult> refreshSeries(String seriesId) {
    return Future<MetadataRefreshBatchResult>.value((
      succeeded: 0,
      failed: 0,
      cancelled: false,
      skipped: false,
      skipMessage: null,
    ));
  }

  @override
  void cancelActive() {}

  @override
  Future<MetadataRefreshBatchResult> refreshLibrary(String libraryId) {
    return onRefreshLibrary?.call(libraryId) ??
        Future<MetadataRefreshBatchResult>.value((
          succeeded: 0,
          failed: 0,
          cancelled: false,
          skipped: false,
          skipMessage: null,
        ));
  }
}

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  _FakeLibraryRevisionPort(this._events);

  final StreamController<void> _events;

  @override
  Stream<void> watchRevision() => _events.stream;
}

class _IdleScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}

void main() {
  test('refreshComic bumps library revision after success', () async {
    final StreamController<void> events = StreamController<void>.broadcast();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        metadataRefreshPortProvider.overrideWithValue(
          _ScriptedRefreshAdapter(
            onRefreshComic: (String comicId) async {
              expect(comicId, 'c1');
            },
          ),
        ),
        libraryRevisionPortProvider.overrideWithValue(
          _FakeLibraryRevisionPort(events),
        ),
        scanLibraryControllerProvider.overrideWith(_IdleScanLibraryController.new),
      ],
    );
    addTearDown(container.dispose);

    final int before = container.read(libraryRevisionProvider).revision;
    await container
        .read(metadataRefreshControllerProvider.notifier)
        .refreshComic(comicId: 'c1', title: 'T');
    final int after = container.read(libraryRevisionProvider).revision;

    expect(after, greaterThan(before));
  });

  test('refreshLibrary does not bump revision when skipped', () async {
    final StreamController<void> events = StreamController<void>.broadcast();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        metadataRefreshPortProvider.overrideWithValue(
          _ScriptedRefreshAdapter(
            onRefreshLibrary: (String libraryId) async {
              return (
                succeeded: 0,
                failed: 0,
                cancelled: false,
                skipped: true,
                skipMessage: 'skip',
              );
            },
          ),
        ),
        libraryRevisionPortProvider.overrideWithValue(
          _FakeLibraryRevisionPort(events),
        ),
        scanLibraryControllerProvider.overrideWith(_IdleScanLibraryController.new),
      ],
    );
    addTearDown(container.dispose);

    final int before = container.read(libraryRevisionProvider).revision;
    await container
        .read(metadataRefreshControllerProvider.notifier)
        .refreshLibrary(libraryId: 'lib-remote', name: 'R');
    final int after = container.read(libraryRevisionProvider).revision;

    expect(after, before);
  });
}
