import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

void main() {
  test('HomeLibraryDashboardRow copyWith updates busy flags', () {
    const HomeLibraryDashboardRow row = HomeLibraryDashboardRow(
      libraryId: 'id',
      displayName: 'name',
      kind: HomeLibraryKind.local,
      comicCount: 1,
      seriesCount: 1,
    );

    final HomeLibraryDashboardRow scanning = row.copyWith(scanInProgress: true);
    expect(scanning.scanInProgress, isTrue);
    expect(scanning.busy, isTrue);
  });
}
