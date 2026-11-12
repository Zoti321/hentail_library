import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';
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
