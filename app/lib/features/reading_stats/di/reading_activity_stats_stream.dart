import 'package:hentai_library/features/reading_stats/data/repositories/reading_activity_stats_repository_impl.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats.dart';

Stream<ReadingActivityStats> createReadingActivityStatsStream() =>
    const ReadingActivityStatsRepositoryImpl().watchActivityStats();
