import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats.dart';
import 'package:hentai_library/features/reading_stats/domain/record_read_session_activity_command.dart';

final homePageCountsProvider = StreamProvider.autoDispose
    .family<HomePageCounts, bool>(
      (ref, excludeR18) => throw UnimplementedError('homePageCountsProvider'),
    );
final readingActivityStatsProvider = StreamProvider<ReadingActivityStats>(
  (ref) => throw UnimplementedError('readingActivityStatsProvider'),
);
final Provider<RecordReadSessionActivityCommand>
recordReadSessionActivityCommandProvider = requiredProvider(
  'recordReadSessionActivityCommandProvider',
);
