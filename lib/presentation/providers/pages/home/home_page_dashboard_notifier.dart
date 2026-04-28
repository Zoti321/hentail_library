import 'package:hentai_library/database/dao/dao.dart';
import 'package:hentai_library/database/dao/home_page_dao_types.dart';
import 'package:hentai_library/presentation/dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_dashboard_notifier.g.dart';

@Riverpod(keepAlive: true)
Stream<HomePageCounts> homePageCountsStream(Ref ref) {
  final HomePageDao dao = ref.watch(homePageDaoProvider);
  return dao.watchHomePageCounts();
}

@Riverpod(keepAlive: true)
Stream<List<HomeContinueReadingEntry>> homeContinueReadingTop5Stream(Ref ref) {
  final bool isHealthy =
      (ref.watch(settingsProvider).value?.isHealthyMode) ?? false;
  final HomePageDao dao = ref.watch(homePageDaoProvider);
  if (isHealthy) {
    return dao.watchContinueReadingTop5Healthy();
  }
  return dao.watchContinueReadingTop5();
}

@Riverpod(keepAlive: true)
Stream<Map<String, int>> homeSeriesComicOrderMapStream(Ref ref) {
  return ref.watch(homePageDaoProvider).watchHomeSeriesComicOrderMap();
}

@Riverpod(keepAlive: true)
List<HistoryGridItemDto> homeContinueReadingTop5GridItems(Ref ref) {
  final List<HomeContinueReadingEntry> entries = ref
      .watch(homeContinueReadingTop5StreamProvider)
      .maybeWhen(
        data: (List<HomeContinueReadingEntry> data) => data,
        orElse: () => const <HomeContinueReadingEntry>[],
      );
  if (entries.isEmpty) {
    return const <HistoryGridItemDto>[];
  }
  final Map<String, int> orderMap = ref
      .watch(homeSeriesComicOrderMapStreamProvider)
      .maybeWhen(
        data: (Map<String, int> m) => m,
        orElse: () => const <String, int>{},
      );
  return entries
      .map((HomeContinueReadingEntry e) => _mapHomeEntryToGridDto(e, orderMap))
      .toList(growable: false);
}

HistoryGridItemDto _mapHomeEntryToGridDto(
  HomeContinueReadingEntry e,
  Map<String, int> orderMap,
) {
  if (e.kind == HomeContinueReadingKind.comic) {
    final String comicId = e.comicId!;
    final String title = e.title!;
    return HistoryGridItemDto.comic(
      id: 'comic:$comicId',
      title: title,
      lastReadTime: e.lastReadTime,
      coverComicId: comicId,
      comicId: comicId,
      pageIndex: e.pageIndex,
    );
  }
  final String seriesName = e.seriesName!;
  final String lastReadComicId = e.lastReadComicId!;
  return HistoryGridItemDto.series(
    id: 'series:$seriesName',
    title: seriesName,
    lastReadTime: e.lastReadTime,
    coverComicId: lastReadComicId,
    seriesName: seriesName,
    lastReadComicId: lastReadComicId,
    pageIndex: e.pageIndex,
    lastReadComicOrder: orderMap['$seriesName|$lastReadComicId'],
  );
}
