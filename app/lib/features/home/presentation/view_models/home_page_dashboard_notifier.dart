import 'package:hentai_library/features/library_browse/public/library_age_restriction_filter.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_alert_dismiss_notifier.dart';
import 'package:hentai_library/core/util/stream_throttle.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/reading_stats_providers.dart';
import 'package:hentai_library/shared/domain/library/home_page_counts.dart';
import 'package:hentai_library/shared/domain/ports/home_page_counts_port.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_dashboard_notifier.g.dart';

const Duration _kHomeScanThrottleInterval = Duration(seconds: 2);

bool _homeExcludeR18(LibraryAgeRestrictionFilter filter) {
  return filter == LibraryAgeRestrictionFilter.allAges;
}

/// 首页计数/列表使用的 Comics 年龄限制（模块当前意图）。
LibraryAgeRestrictionFilter _comicsAgeRestriction(Ref ref) {
  return ref.watch(libraryComicAgeRestrictionStateProvider);
}

/// Home page counts 单一装配缝：经 `reading_stats` public Port。
@Riverpod(keepAlive: true)
Stream<HomePageCounts> homePageCountsStream(Ref ref) {
  final HomePageCountsPort port = ref.watch(homePageCountsPortProvider);
  final bool excludeR18 = _homeExcludeR18(_comicsAgeRestriction(ref));
  ref.watch(libraryRevisionThrottleBusyStateProvider);
  // 字典变更时重建，确保 parody/character 与管理页口径一致。
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  return throttleWhile(
    port.watchHomePageCounts(excludeR18: excludeR18),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyStateProvider),
    interval: _kHomeScanThrottleInterval,
  );
}

@Riverpod(keepAlive: true)
Stream<List<HomeLibraryAlert>> homeLibraryAlertsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  ref.watch(libraryRevisionThrottleBusyStateProvider);
  final AsyncValue<Map<String, HomeAlertDismissEntry>> dismissedAsync = ref
      .watch(homeAlertDismissStoreProvider);
  return throttleWhile(
    repository.watchHomeLibraryAlerts().map((List<HomeLibraryAlert> alerts) {
      final Map<String, HomeAlertDismissEntry> dismissed =
          dismissedAsync.asData?.value ??
          const <String, HomeAlertDismissEntry>{};
      return filterDismissedHomeAlerts(alerts: alerts, dismissed: dismissed);
    }),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyStateProvider),
    interval: _kHomeScanThrottleInterval,
  );
}
