import 'package:hentai_library/features/home/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel exports cross-feature types, factories, page, and bootstrap hooks', () {
    expect(HomeLibraryStat, isNotNull);
    expect(HomeLibraryAlert, isNotNull);
    expect(HomePageRepository, isNotNull);
    expect(homeLibraryStatsStreamProvider, isNotNull);
    expect(HomePage, isNotNull);
  });
}
