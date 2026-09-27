import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_alert_dismiss_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_probe_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_throttle_busy.dart';
import 'package:hentai_library/ui/features/shell/view_models/stream_throttle.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_dashboard_notifier.g.dart';

const Duration _kHomeScanThrottleInterval = Duration(seconds: 2);

bool _homeExcludeR18(LibraryAgeRestrictionFilter filter) {
  return filter == LibraryAgeRestrictionFilter.allAges;
}

@Riverpod(keepAlive: true)
Stream<HomePageCounts> homePageCountsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  final bool excludeR18 = _homeExcludeR18(
    ref.watch(libraryComicsTabAgeRestrictionFilterProvider),
  );
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
  final bool excludeR18 = _homeExcludeR18(
    ref.watch(libraryComicsTabAgeRestrictionFilterProvider),
  );
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
  final bool excludeR18 = _homeExcludeR18(
    ref.watch(libraryComicsTabAgeRestrictionFilterProvider),
  );
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
  final AsyncValue<Map<String, int>> dismissedAsync = ref.watch(
    homeAlertDismissStoreProvider,
  );
  final Map<String, LibraryProbeResult> probeResults = ref.watch(
    homeProbeResultsProvider,
  );
  return throttleWhile(
    repository.watchHomeLibraryAlerts().map((List<HomeLibraryAlert> alerts) {
      final List<HomeLibraryAlert> merged = _mergeProbeAlerts(
        alerts,
        probeResults,
      );
      final Map<String, int> dismissed =
          dismissedAsync.asData?.value ?? const <String, int>{};
      return filterDismissedHomeAlerts(
        alerts: merged,
        dismissed: dismissed,
      );
    }),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyProvider),
    interval: _kHomeScanThrottleInterval,
  );
}

List<HomeLibraryAlert> _mergeProbeAlerts(
  List<HomeLibraryAlert> base,
  Map<String, LibraryProbeResult> probeResults,
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
          : result.libraryId,
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
