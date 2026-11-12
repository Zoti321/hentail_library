import 'package:hentai_library/features/reading_stats/domain/finished_comic_policy_domain_service.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_activity_stats_repository.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_duration_accrual_domain_service.dart';

/// 将 Read session 事实经领域规则写入 Reading activity stats。
class RecordReadSessionActivity {
  const RecordReadSessionActivity(this._repository);

  final ReadingActivityStatsRepository _repository;

  Future<void> record({
    required String comicId,
    required bool incognito,
    required Duration foregroundElapsed,
    required int pageIndex,
    required int pageCount,
  }) {
    final Duration? accrued =
        ReadingDurationAccrualDomainService.accruedDuration(
          incognito: incognito,
          foregroundElapsed: foregroundElapsed,
        );
    final bool markFinished =
        FinishedComicPolicyDomainService.shouldMarkFinished(
          incognito: incognito,
          pageIndex: pageIndex,
          pageCount: pageCount,
        );
    if (accrued == null && !markFinished) {
      return Future<void>.value();
    }
    return _repository.recordSessionActivity(
      comicId: comicId,
      addDuration: accrued,
      markFinished: markFinished,
    );
  }
}
