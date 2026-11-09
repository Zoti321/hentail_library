import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_stats/public.dart';

void main() {
  test('public barrel exports Home page counts types and port factory', () {
    expect(HomePageCounts, isNotNull);
    expect(createHomePageCountsPort, isNotNull);
  });
}
