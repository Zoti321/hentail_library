import 'package:hentai_library/core/util/stream_throttle.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/library/home_library_stat.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_library_stats_stream.g.dart';

const Duration _kHomeLibraryStatsThrottleInterval = Duration(seconds: 2);

bool _excludeR18(LibraryAgeRestrictionFilter filter) {
  return filter == LibraryAgeRestrictionFilter.allAges;
}

/// 各库漫画/系列计数（Home 仪表盘与库管理面板共用）。
@Riverpod(keepAlive: true)
Stream<List<HomeLibraryStat>> homeLibraryStatsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  final bool excludeR18 = _excludeR18(
    ref.watch(libraryComicAgeRestrictionStateProvider),
  );
  ref.watch(libraryRevisionThrottleBusyStateProvider);
  return throttleWhile(
    repository.watchLibraryStats(excludeR18: excludeR18),
    shouldThrottle: () => ref.read(libraryRevisionThrottleBusyStateProvider),
    interval: _kHomeLibraryStatsThrottleInterval,
  );
}
