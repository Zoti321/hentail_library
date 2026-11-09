import 'package:hentai_library/features/reading_stats/application/record_read_session_activity.dart';
import 'package:hentai_library/features/reading_stats/data/repositories/reading_activity_stats_repository_impl.dart';
import 'package:hentai_library/shared/domain/ports/record_read_session_activity_port.dart';

RecordReadSessionActivityPort createRecordReadSessionActivityPort() =>
    const RecordReadSessionActivity(ReadingActivityStatsRepositoryImpl());
