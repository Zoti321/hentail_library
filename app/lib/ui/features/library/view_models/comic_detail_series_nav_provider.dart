import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_series_providers.dart';
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

class ComicDetailSeriesNavSeriesData {
  const ComicDetailSeriesNavSeriesData({
    required this.seriesId,
    required this.seriesName,
    required this.items,
  });

  final String seriesId;
  final String seriesName;
  final List<ComicDetailSeriesNavItem> items;
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

Future<ComicDetailSeriesNavSeriesData?> buildSeriesNavData(
  Ref ref,
  Series series,
) async {
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
  if (items.isEmpty) {
    return null;
  }
  return ComicDetailSeriesNavSeriesData(
    seriesId: series.id,
    seriesName: series.name,
    items: items,
  );
}

ComicDetailSeriesNavResult resolveComicDetailSeriesNavResult(
  List<Series> allSeries,
  String comicId,
  ComicDetailSeriesNavSeriesData? seriesData,
) {
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
  if (seriesData == null) {
    return const ComicDetailSeriesNavNone();
  }
  final int currentIndex = seriesData.items.indexWhere(
    (ComicDetailSeriesNavItem item) => item.comicId == comicId,
  );
  if (currentIndex < 0) {
    return const ComicDetailSeriesNavNone();
  }
  return ComicDetailSeriesNavReady(
    ComicDetailSeriesNavData(
      seriesId: seriesData.seriesId,
      seriesName: seriesData.seriesName,
      items: seriesData.items,
      currentIndex: currentIndex,
    ),
  );
}

@Riverpod(keepAlive: true)
Future<ComicDetailSeriesNavSeriesData?> comicDetailSeriesNavForSeries(
  Ref ref,
  String seriesId,
) async {
  final Series? series = await ref.watch(seriesByIdProvider(seriesId).future);
  if (series == null) {
    return null;
  }
  return buildSeriesNavData(ref, series);
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

  final ComicDetailSeriesNavSeriesData? seriesData = await ref.watch(
    comicDetailSeriesNavForSeriesProvider(matches.single.id).future,
  );
  return resolveComicDetailSeriesNavResult(allSeries, comicId, seriesData);
}
