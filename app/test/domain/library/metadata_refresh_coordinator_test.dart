import 'package:hentai_library/data/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/domain/library/metadata_refresh_coordinator.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:test/test.dart';

class _FakeLibraryRepository implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScriptedRefreshAdapter extends MetadataRefreshFrbAdapter {
  _ScriptedRefreshAdapter({
    this.onRefreshComic,
    this.onRefreshSeries,
    this.onRefreshLibrary,
  }) : super(libraryRepository: _FakeLibraryRepository());

  final Future<void> Function(String comicId)? onRefreshComic;
  final Future<MetadataRefreshBatchResult> Function(String seriesId)?
  onRefreshSeries;
  final Future<MetadataRefreshBatchResult> Function(String libraryId)?
  onRefreshLibrary;

  @override
  Future<void> refreshComic(String comicId) {
    return onRefreshComic?.call(comicId) ?? Future<void>.value();
  }

  @override
  Future<MetadataRefreshBatchResult> refreshSeries(String seriesId) {
    return onRefreshSeries?.call(seriesId) ??
        Future<MetadataRefreshBatchResult>.value((
          succeeded: 0,
          failed: 0,
          cancelled: false,
          skipped: false,
          skipMessage: null,
        ));
  }

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

void main() {
  test(
    'refreshComic notifies catalog revision after adapter succeeds',
    () async {
      var notifyCount = 0;
      String? seenId;
      final MetadataRefreshCoordinator coordinator = MetadataRefreshCoordinator(
        adapter: _ScriptedRefreshAdapter(
          onRefreshComic: (String comicId) async {
            seenId = comicId;
          },
        ),
        onSucceeded: () => notifyCount++,
      );

      await coordinator.refreshComic('c1');

      expect(seenId, 'c1');
      expect(notifyCount, 1);
    },
  );

  test(
    'refreshSeries notifies catalog revision after adapter succeeds',
    () async {
      var notifyCount = 0;
      final MetadataRefreshCoordinator coordinator = MetadataRefreshCoordinator(
        adapter: _ScriptedRefreshAdapter(
          onRefreshSeries: (String seriesId) async {
            expect(seriesId, 's1');
            return (
              succeeded: 1,
              failed: 0,
              cancelled: false,
              skipped: false,
              skipMessage: null,
            );
          },
        ),
        onSucceeded: () => notifyCount++,
      );

      final MetadataRefreshBatchResult result = await coordinator.refreshSeries(
        's1',
      );

      expect(result.succeeded, 1);
      expect(result.cancelled, isFalse);
      expect(notifyCount, 1);
    },
  );

  test(
    'refreshLibrary notifies catalog revision after a non-skipped result',
    () async {
      var notifyCount = 0;
      final MetadataRefreshCoordinator coordinator = MetadataRefreshCoordinator(
        adapter: _ScriptedRefreshAdapter(
          onRefreshLibrary: (String libraryId) async {
            expect(libraryId, 'lib-1');
            return (
              succeeded: 2,
              failed: 1,
              cancelled: false,
              skipped: false,
              skipMessage: null,
            );
          },
        ),
        onSucceeded: () => notifyCount++,
      );

      final MetadataRefreshBatchResult result = await coordinator
          .refreshLibrary('lib-1');

      expect(result.succeeded, 2);
      expect(result.failed, 1);
      expect(notifyCount, 1);
    },
  );

  test(
    'refreshLibrary does not notify catalog revision when remote library is skipped',
    () async {
      var notifyCount = 0;
      final MetadataRefreshCoordinator coordinator = MetadataRefreshCoordinator(
        adapter: _ScriptedRefreshAdapter(
          onRefreshLibrary: (String libraryId) async {
            return (
              succeeded: 0,
              failed: 0,
              cancelled: false,
              skipped: true,
              skipMessage: '已跳过远程库（缺少凭证）: https://nas.example/dav',
            );
          },
        ),
        onSucceeded: () => notifyCount++,
      );

      final MetadataRefreshBatchResult result = await coordinator
          .refreshLibrary('lib-remote');

      expect(result.skipped, isTrue);
      expect(notifyCount, 0);
    },
  );
}
