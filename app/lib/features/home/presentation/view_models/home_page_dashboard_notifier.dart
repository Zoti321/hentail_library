import 'dart:async';

import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_alert_dismiss_notifier.dart';
import 'package:hentai_library/core/util/stream_throttle.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/home/public/di/home_page_providers.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
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

/// Home page counts 单一装配缝：经 `reading_stats` public 状态。
@Riverpod(keepAlive: true)
Stream<HomePageCounts> homePageCountsStream(Ref ref) {
  final bool excludeR18 = _homeExcludeR18(_comicsAgeRestriction(ref));
  ref.watch(libraryRevisionThrottleBusyStateProvider);
  return throttleWhile(
    _observeStream(ref, homePageCountsProvider(excludeR18)),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyStateProvider),
    interval: _kHomeScanThrottleInterval,
  );
}

/// Reading activity stats 装配缝：经 `reading_stats` 共享状态。
@Riverpod(keepAlive: true)
Stream<ReadingActivityStats> readingActivityStatsStream(Ref ref) {
  ref.watch(libraryRevisionThrottleBusyStateProvider);
  return throttleWhile(
    _observeStream(ref, readingActivityStatsProvider),
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

Stream<T> _observeStream<T>(Ref ref, StreamProvider<T> provider) {
  final controller = StreamController<T>();
  ref.listen<AsyncValue<T>>(provider, (previous, next) {
    switch (next) {
      case AsyncData<T>(:final value):
        controller.add(value);
      case AsyncError<T>(:final error, :final stackTrace):
        controller.addError(error, stackTrace);
      case AsyncLoading<T>():
        break;
    }
  }, fireImmediately: true);
  ref.onDispose(controller.close);
  return controller.stream;
}
