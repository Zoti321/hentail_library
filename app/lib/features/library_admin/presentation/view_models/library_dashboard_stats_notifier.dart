import 'package:hentai_library/core/util/stream_throttle.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_dashboard_stats_notifier.g.dart';

const Duration _kLibraryDashboardStatsThrottleInterval = Duration(seconds: 2);

bool _excludeR18(LibraryAgeRestrictionFilter filter) {
  return filter == LibraryAgeRestrictionFilter.allAges;
}

@Riverpod(keepAlive: true)
Stream<List<HomeLibraryStat>> libraryDashboardStatsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  final bool excludeR18 = _excludeR18(
    ref.watch(libraryComicAgeRestrictionStateProvider),
  );
  ref.watch(libraryRevisionThrottleBusyStateProvider);
  return throttleWhile(
    repository.watchLibraryStats(excludeR18: excludeR18),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyStateProvider),
    interval: _kLibraryDashboardStatsThrottleInterval,
  );
}
