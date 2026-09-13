import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_external_exit.dart';
import 'package:hentai_library/ui/features/shell/state/metadata_refresh_controller.dart';

void main() {
  group('shouldExitSeriesReorderAfterScan', () {
    test('exits only on running true→false', () {
      expect(
        shouldExitSeriesReorderAfterScan(
          previousRunning: true,
          nextRunning: false,
        ),
        isTrue,
      );
      expect(
        shouldExitSeriesReorderAfterScan(
          previousRunning: false,
          nextRunning: true,
        ),
        isFalse,
      );
      expect(
        shouldExitSeriesReorderAfterScan(
          previousRunning: null,
          nextRunning: false,
        ),
        isFalse,
      );
      expect(
        shouldExitSeriesReorderAfterScan(
          previousRunning: true,
          nextRunning: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldExitSeriesReorderAfterMetadataRefresh', () {
    test('exits when this series refresh finishes', () {
      expect(
        shouldExitSeriesReorderAfterMetadataRefresh(
          previous: const MetadataRefreshState(
            running: true,
            targetKind: MetadataRefreshTargetKind.series,
            targetId: 'series-1',
          ),
          next: const MetadataRefreshState(),
          seriesId: 'series-1',
        ),
        isTrue,
      );
    });

    test('exits when library refresh finishes', () {
      expect(
        shouldExitSeriesReorderAfterMetadataRefresh(
          previous: const MetadataRefreshState(
            running: true,
            targetKind: MetadataRefreshTargetKind.library,
            targetId: 'lib-1',
          ),
          next: const MetadataRefreshState(),
          seriesId: 'series-1',
        ),
        isTrue,
      );
    });

    test('ignores other series, comic-only, and still-running refresh', () {
      expect(
        shouldExitSeriesReorderAfterMetadataRefresh(
          previous: const MetadataRefreshState(
            running: true,
            targetKind: MetadataRefreshTargetKind.series,
            targetId: 'other',
          ),
          next: const MetadataRefreshState(),
          seriesId: 'series-1',
        ),
        isFalse,
      );
      expect(
        shouldExitSeriesReorderAfterMetadataRefresh(
          previous: const MetadataRefreshState(
            running: true,
            targetKind: MetadataRefreshTargetKind.comic,
            targetId: 'comic-1',
          ),
          next: const MetadataRefreshState(),
          seriesId: 'series-1',
        ),
        isFalse,
      );
      expect(
        shouldExitSeriesReorderAfterMetadataRefresh(
          previous: const MetadataRefreshState(
            running: true,
            targetKind: MetadataRefreshTargetKind.series,
            targetId: 'series-1',
          ),
          next: const MetadataRefreshState(
            running: true,
            targetKind: MetadataRefreshTargetKind.series,
            targetId: 'series-1',
          ),
          seriesId: 'series-1',
        ),
        isFalse,
      );
    });
  });
}
