import 'package:hentai_library/composition/modules/reading_stats/home_page_counts_repository.dart';
import 'package:hentai_library/composition/modules/reading_stats/reading_activity_stats_stream.dart';
import 'package:hentai_library/composition/modules/reading_stats/record_read_session_activity_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_revisions.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> readingStatsSharedStateOverrides() => <Override>[
  homePageCountsProvider.overrideWith((Ref ref, bool excludeR18) {
    // 字典变更时重建，确保 parody/character 与管理页口径一致。
    ref.watch(
      domainEventRevisionsProvider.select(
        (DomainEventRevisionsState s) => s.dictionaryRevision,
      ),
    );
    return createHomePageCountsRepository(ref)
        .watchHomePageCounts(excludeR18: excludeR18);
  }),
  readingActivityStatsProvider.overrideWith(
    (ref) => createReadingActivityStatsStream(),
  ),
  recordReadSessionActivityCommandProvider.overrideWithValue(
    createRecordReadSessionActivityCommand(),
  ),
];
