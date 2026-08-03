import 'package:hentai_library/data/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/domain/library/metadata_refresh_coordinator.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';
import 'package:test/test.dart';

class _ScriptedRefreshAdapter extends MetadataRefreshFrbAdapter {
  _ScriptedRefreshAdapter({this.onRefreshComic, this.onRefreshSeries});

  final Future<void> Function(String comicId)? onRefreshComic;
  final Future<RefreshSeriesResult> Function(
    String seriesId, {
    void Function(RefreshSeriesProgress progress)? onProgress,
  })?
  onRefreshSeries;

  @override
  Future<void> refreshComic(String comicId) {
    return onRefreshComic?.call(comicId) ?? Future<void>.value();
  }

  @override
  Future<RefreshSeriesResult> refreshSeries(
    String seriesId, {
    void Function(RefreshSeriesProgress progress)? onProgress,
  }) {
    return onRefreshSeries?.call(seriesId, onProgress: onProgress) ??
        Future<RefreshSeriesResult>.value((succeeded: 0, failed: 0));
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
          onRefreshSeries:
              (
                String seriesId, {
                void Function(RefreshSeriesProgress progress)? onProgress,
              }) async {
                onProgress?.call((
                  current: 1,
                  total: 1,
                  comicId: 'c1',
                  succeeded: 1,
                  failed: 0,
                ));
                return (succeeded: 1, failed: 0);
              },
        ),
        onSucceeded: () => notifyCount++,
      );

      final RefreshSeriesResult result = await coordinator.refreshSeries('s1');

      expect(result.succeeded, 1);
      expect(notifyCount, 1);
    },
  );
}
