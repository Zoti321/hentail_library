import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_stats/public.dart';

void main() {
  test('public barrel exports counts / activity types and port factories', () {
    expect(HomePageCounts, isNotNull);
    expect(ReadingActivityStats, isNotNull);
    expect(createHomePageCountsPort, isNotNull);
    expect(createReadingActivityStatsPort, isNotNull);
  });
}
