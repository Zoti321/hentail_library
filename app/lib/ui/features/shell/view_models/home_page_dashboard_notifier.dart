import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/stream_throttle.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_dashboard_notifier.g.dart';

const Duration _kHomeScanThrottleInterval = Duration(seconds: 2);

@Riverpod(keepAlive: true)
Stream<HomePageCounts> homePageCountsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  // Rebuild subscription when scan running flips so pass-through resumes promptly.
  ref.watch(scanLibraryControllerProvider.select((s) => s.running));
  return throttleWhile(
    repository.watchHomePageCounts(),
    shouldThrottle: () => ref.read(scanLibraryControllerProvider).running,
    interval: _kHomeScanThrottleInterval,
  );
}

@Riverpod(keepAlive: true)
Stream<List<HomeContinueReadingEntry>> homeContinueReadingTop5Stream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  ref.watch(scanLibraryControllerProvider.select((s) => s.running));
  return throttleWhile(
    repository.watchContinueReadingTop5(excludeR18: false),
    shouldThrottle: () => ref.read(scanLibraryControllerProvider).running,
    interval: _kHomeScanThrottleInterval,
  );
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
