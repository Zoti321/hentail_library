import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/shared/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/shared/ui/dto/history_grid_item.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_alert_dismiss_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_probe_coordinator_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_throttle_busy.dart';
import 'package:hentai_library/shared/core/util/stream_throttle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_dashboard_notifier.g.dart';

const Duration _kHomeScanThrottleInterval = Duration(seconds: 2);

bool _homeExcludeR18(LibraryAgeRestrictionFilter filter) {
  return filter == LibraryAgeRestrictionFilter.allAges;
}

/// 首页计数/列表使用的 Comics 年龄限制（模块当前意图）。
LibraryAgeRestrictionFilter _comicsAgeRestriction(Ref ref) {
  return ref.watch(
    libraryComicFiltersProvider.select(
      (AsyncValue<LibraryComicFiltersState> state) =>
          state.value?.ageRestriction ??
          LibraryAgeRestrictionFilter.unrestricted,
    ),
  );
}

@Riverpod(keepAlive: true)
Stream<HomePageCounts> homePageCountsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  final bool excludeR18 = _homeExcludeR18(_comicsAgeRestriction(ref));
  ref.watch(libraryRevisionThrottleBusyProvider);
  return throttleWhile(
    repository.watchHomePageCounts(excludeR18: excludeR18),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyProvider),
    interval: _kHomeScanThrottleInterval,
  );
}

@Riverpod(keepAlive: true)
Stream<List<HomeContinueReadingEntry>> homeContinueReadingTop5Stream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  final bool excludeR18 = _homeExcludeR18(_comicsAgeRestriction(ref));
  ref.watch(libraryRevisionThrottleBusyProvider);
  return throttleWhile(
    repository.watchContinueReadingTop5(excludeR18: excludeR18),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyProvider),
    interval: _kHomeScanThrottleInterval,
  );
}

@Riverpod(keepAlive: true)
Stream<List<HomeRecentlyAddedEntry>> homeRecentlyAddedStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  final bool excludeR18 = _homeExcludeR18(_comicsAgeRestriction(ref));
  ref.watch(libraryRevisionThrottleBusyProvider);
  return throttleWhile(
    repository.watchRecentlyAddedOnHome(excludeR18: excludeR18),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyProvider),
    interval: _kHomeScanThrottleInterval,
  );
}

@Riverpod(keepAlive: true)
Stream<List<HomeLibraryAlert>> homeLibraryAlertsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  ref.watch(libraryRevisionThrottleBusyProvider);
  ref.watch(homeProbeResultsProvider);
  ref.watch(homeAlertDismissRevisionProvider);
  final AsyncValue<Map<String, HomeAlertDismissEntry>> dismissedAsync = ref
      .watch(homeAlertDismissStoreProvider);
  final Map<String, LibraryProbeResult> probeResults = ref.watch(
    homeProbeResultsProvider,
  );
  final Map<String, String> libraryDisplayNames = ref
      .watch(currentLibraryProvider)
      .maybeWhen(
        data: (CurrentLibraryState state) => Map<String, String>.fromEntries(
          state.libraries.map(
            (lib) => MapEntry<String, String>(lib.libraryId, lib.name),
          ),
        ),
        orElse: () => const <String, String>{},
      );
  return throttleWhile(
    repository.watchHomeLibraryAlerts().map((List<HomeLibraryAlert> alerts) {
      final List<HomeLibraryAlert> merged = _mergeProbeAlerts(
        alerts,
        probeResults,
        libraryDisplayNames,
      );
      final Map<String, HomeAlertDismissEntry> dismissed =
          dismissedAsync.asData?.value ??
          const <String, HomeAlertDismissEntry>{};
      return filterDismissedHomeAlerts(alerts: merged, dismissed: dismissed);
    }),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyProvider),
    interval: _kHomeScanThrottleInterval,
  );
}

List<HomeLibraryAlert> _mergeProbeAlerts(
  List<HomeLibraryAlert> base,
  Map<String, LibraryProbeResult> probeResults,
  Map<String, String> libraryDisplayNames,
) {
  if (probeResults.isEmpty) {
    return base;
  }
  final List<HomeLibraryAlert> merged = List<HomeLibraryAlert>.from(base);
  for (final LibraryProbeResult result in probeResults.values) {
    if (result.baselineMissing || result.unreachable) {
      continue;
    }
    final int pending = result.pendingCount;
    if (pending <= 0) {
      merged.removeWhere(
        (HomeLibraryAlert alert) =>
            alert.libraryId == result.libraryId &&
            alert.kind == HomeLibraryAlertKind.pendingResourcesDetected,
      );
      continue;
    }
    final int existingIndex = merged.indexWhere(
      (HomeLibraryAlert alert) => alert.libraryId == result.libraryId,
    );
    final HomeLibraryAlert pendingAlert = HomeLibraryAlert(
      libraryId: result.libraryId,
      displayName: existingIndex >= 0
          ? merged[existingIndex].displayName
          : libraryDisplayNames[result.libraryId] ?? result.libraryId,
      kind: HomeLibraryAlertKind.pendingResourcesDetected,
      pendingResourceCount: pending,
    );
    merged.removeWhere(
      (HomeLibraryAlert alert) =>
          alert.libraryId == result.libraryId &&
          alert.kind == HomeLibraryAlertKind.pendingResourcesDetected,
    );
    merged.add(pendingAlert);
  }
  return merged;
}

@Riverpod(keepAlive: true)
List<HistoryGridItem> homeContinueReadingTop5GridItems(Ref ref) {
  final List<HomeContinueReadingEntry> entries = ref
      .watch(homeContinueReadingTop5StreamProvider)
      .maybeWhen(
        data: (List<HomeContinueReadingEntry> data) => data,
        orElse: () => const <HomeContinueReadingEntry>[],
      );
  return entries
      .map(
        (HomeContinueReadingEntry e) => historyGridItem(
          id: 'comic:${e.comicId}',
          title: e.title,
          lastReadTime: e.lastReadTime,
          coverComicId: e.comicId,
          comicId: e.comicId,
          pageIndex: e.pageIndex,
        ),
      )
      .toList(growable: false);
}
