import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_row_health.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 8, 12);

  group('resolveHomeLibraryRowHealth', () {
    test('disabled interval → none', () {
      final result = resolveHomeLibraryRowHealth(
        now: now,
        scanInterval: ScanInterval.disabled,
        lastSuccessfulSyncAt: now.subtract(const Duration(days: 30)),
        comicCount: 10,
      );
      expect(result.hint, HomeLibraryRowHint.none);
      expect(result.staleDays, isNull);
    });

    test('within daily threshold → none', () {
      final result = resolveHomeLibraryRowHealth(
        now: now,
        scanInterval: ScanInterval.daily,
        lastSuccessfulSyncAt: now.subtract(const Duration(hours: 12)),
        comicCount: 10,
      );
      expect(result.hint, HomeLibraryRowHint.none);
      expect(result.staleDays, isNull);
    });

    test('past daily threshold → syncWarning with staleDays', () {
      final result = resolveHomeLibraryRowHealth(
        now: now,
        scanInterval: ScanInterval.daily,
        lastSuccessfulSyncAt: now.subtract(const Duration(days: 9)),
        comicCount: 10,
      );
      expect(result.hint, HomeLibraryRowHint.syncWarning);
      expect(result.staleDays, 9);
    });

    test('no last sync but comics → syncWarning without days', () {
      final result = resolveHomeLibraryRowHealth(
        now: now,
        scanInterval: ScanInterval.weekly,
        lastSuccessfulSyncAt: null,
        comicCount: 3,
      );
      expect(result.hint, HomeLibraryRowHint.syncWarning);
      expect(result.staleDays, isNull);
    });

    test('no last sync and empty library → none', () {
      final result = resolveHomeLibraryRowHealth(
        now: now,
        scanInterval: ScanInterval.daily,
        lastSuccessfulSyncAt: null,
        comicCount: 0,
      );
      expect(result.hint, HomeLibraryRowHint.none);
      expect(result.staleDays, isNull);
    });

    test('sub-day stale floors to 1', () {
      final result = resolveHomeLibraryRowHealth(
        now: now,
        scanInterval: ScanInterval.hourly,
        lastSuccessfulSyncAt: now.subtract(const Duration(hours: 3)),
        comicCount: 1,
      );
      expect(result.hint, HomeLibraryRowHint.syncWarning);
      expect(result.staleDays, 1);
    });
  });
}
