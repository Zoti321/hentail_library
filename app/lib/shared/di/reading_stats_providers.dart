import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/home_page_counts_port.dart';
import 'package:hentai_library/shared/domain/ports/reading_activity_stats_port.dart';

final Provider<HomePageCountsPort> homePageCountsPortProvider =
    Provider<HomePageCountsPort>(
      (Ref ref) => throw UnimplementedError(
        'homePageCountsPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<ReadingActivityStatsPort> readingActivityStatsPortProvider =
    Provider<ReadingActivityStatsPort>(
      (Ref ref) => throw UnimplementedError(
        'readingActivityStatsPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
