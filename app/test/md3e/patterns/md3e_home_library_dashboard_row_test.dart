import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';

void main() {
  test('Md3eHomeLibraryDashboardRow copyWith updates busy flags', () {
    const Md3eHomeLibraryDashboardRow row = Md3eHomeLibraryDashboardRow(
      libraryId: 'id',
      displayName: 'name',
      kind: Md3eHomeLibraryKind.local,
      comicCount: 1,
      seriesCount: 1,
    );

    final Md3eHomeLibraryDashboardRow scanning = row.copyWith(
      scanInProgress: true,
    );
    expect(scanning.scanInProgress, isTrue);
    expect(scanning.busy, isTrue);
  });
}
