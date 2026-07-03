import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item_dto.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_dashboard_notifier.g.dart';

@Riverpod(keepAlive: true)
Stream<HomePageCounts> homePageCountsStream(Ref ref) {
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  return repository.watchHomePageCounts();
}

@Riverpod(keepAlive: true)
Stream<List<HomeContinueReadingEntry>> homeContinueReadingTop5Stream(Ref ref) {
  final bool isHealthy =
      (ref.watch(settingsProvider).value?.isHealthyMode) ?? false;
  final HomePageRepository repository = ref.watch(homePageRepoProvider);
  return repository.watchContinueReadingTop5(excludeR18: isHealthy);
}

@Riverpod(keepAlive: true)
List<HistoryGridItemDto> homeContinueReadingTop5GridItems(Ref ref) {
  final List<HomeContinueReadingEntry> entries = ref
      .watch(homeContinueReadingTop5StreamProvider)
      .maybeWhen(
        data: (List<HomeContinueReadingEntry> data) => data,
        orElse: () => const <HomeContinueReadingEntry>[],
      );
  return entries
      .map(
        (HomeContinueReadingEntry e) => HistoryGridItemDto(
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
