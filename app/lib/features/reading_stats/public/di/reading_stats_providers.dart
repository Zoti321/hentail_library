import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_port.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats_port.dart';
import 'package:hentai_library/features/reading_stats/domain/record_read_session_activity_port.dart';

final Provider<HomePageCountsPort> homePageCountsPortProvider = injectedDi(
  'homePageCountsPortProvider',
);

final Provider<ReadingActivityStatsPort> readingActivityStatsPortProvider =
    injectedDi('readingActivityStatsPortProvider');

final Provider<RecordReadSessionActivityPort>
recordReadSessionActivityPortProvider = injectedDi(
  'recordReadSessionActivityPortProvider',
);
