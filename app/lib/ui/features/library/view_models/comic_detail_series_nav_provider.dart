import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_detail_series_nav_provider.g.dart';

class ComicDetailSeriesNavItem {
  const ComicDetailSeriesNavItem({
    required this.displayIndex,
    required this.comicId,
    required this.title,
  });

  final int displayIndex;
  final String comicId;
  final String title;

  String get menuLabel => '$displayIndex-$title';
}

class ComicDetailSeriesNavData {
  const ComicDetailSeriesNavData({
    required this.seriesId,
    required this.seriesName,
    required this.items,
    required this.currentIndex,
  });

  final String seriesId;
  final String seriesName;
  final List<ComicDetailSeriesNavItem> items;
  final int currentIndex;

  bool get hasPrevious => currentIndex > 0;

  bool get hasNext => currentIndex >= 0 && currentIndex < items.length - 1;

  ComicDetailSeriesNavItem? get previousItem =>
      hasPrevious ? items[currentIndex - 1] : null;

  ComicDetailSeriesNavItem? get nextItem =>
      hasNext ? items[currentIndex + 1] : null;
}

sealed class ComicDetailSeriesNavResult {
  const ComicDetailSeriesNavResult();
}

final class ComicDetailSeriesNavNone extends ComicDetailSeriesNavResult {
  const ComicDetailSeriesNavNone();
}

final class ComicDetailSeriesNavReady extends ComicDetailSeriesNavResult {
  const ComicDetailSeriesNavReady(this.data);

  final ComicDetailSeriesNavData data;
}

final class ComicDetailSeriesNavConflict extends ComicDetailSeriesNavResult {
  const ComicDetailSeriesNavConflict(this.seriesNames);

  final List<String> seriesNames;
}

String comicTitleFallbackForDisplay(String comicId) {
  return comicId.length > 12 ? '${comicId.substring(0, 12)}…' : comicId;
}

Future<String> resolveComicTitleForDisplay(
  ComicRepository repo,
  String comicId,
) async {
  final comic = await repo.findById(comicId);
  return comic?.title ?? comicTitleFallbackForDisplay(comicId);
}

List<Series> findSeriesListContainingComic(
  List<Series> allSeries,
  String comicId,
) {
  return allSeries
      .where((Series series) => series.containsComic(comicId))
      .toList();
}

@Riverpod(keepAlive: true)
Future<ComicDetailSeriesNavResult> comicDetailSeriesNav(
  Ref ref,
  String comicId,
) async {
  final List<Series> allSeries = await ref.watch(allSeriesProvider.future);
  final List<Series> matches = findSeriesListContainingComic(
    allSeries,
    comicId,
  );
  if (matches.isEmpty) {
    return const ComicDetailSeriesNavNone();
  }
  if (matches.length > 1) {
    return ComicDetailSeriesNavConflict(
      matches.map((Series series) => series.name).toList(),
    );
  }

  final Series series = matches.single;
  final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  final ComicRepository repo = ref.read(comicRepoProvider);
  final List<ComicDetailSeriesNavItem> items = <ComicDetailSeriesNavItem>[];
  for (int index = 0; index < sortedItems.length; index++) {
    final SeriesItem item = sortedItems[index];
    final String title = await resolveComicTitleForDisplay(repo, item.comicId);
    items.add(
      ComicDetailSeriesNavItem(
        displayIndex: index + 1,
        comicId: item.comicId,
        title: title,
      ),
    );
  }
  final int currentIndex = items.indexWhere(
    (ComicDetailSeriesNavItem item) => item.comicId == comicId,
  );
  if (currentIndex < 0) {
    return const ComicDetailSeriesNavNone();
  }
  return ComicDetailSeriesNavReady(
    ComicDetailSeriesNavData(
      seriesId: series.id,
      seriesName: series.name,
      items: items,
      currentIndex: currentIndex,
    ),
  );
}
