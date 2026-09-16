import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/reading/series_reading_context.dart';
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

String comicTitleFallbackForDisplay(String comicId) {
  return comicId.length > 12 ? '${comicId.substring(0, 12)}…' : comicId;
}

Future<String> resolveComicTitleForDisplay(
  ComicRepository repo,
  String comicId,
) async {
  final Map<String, String> titles = await resolveComicTitlesForDisplay(
    repo,
    <String>[comicId],
  );
  return titles[comicId] ?? comicTitleFallbackForDisplay(comicId);
}

/// Resolves display titles for [comicIds] with one batch repository read.
/// Missing ids keep the truncated-id fallback; found order follows [comicIds].
Future<Map<String, String>> resolveComicTitlesForDisplay(
  ComicRepository repo,
  List<String> comicIds,
) async {
  if (comicIds.isEmpty) {
    return const <String, String>{};
  }
  final List<Comic> comics = await repo.findByIds(comicIds);
  final Map<String, String> titlesById = <String, String>{
    for (final Comic comic in comics) comic.comicId: comic.title,
  };
  return <String, String>{
    for (final String comicId in comicIds)
      comicId: titlesById[comicId] ?? comicTitleFallbackForDisplay(comicId),
  };
}

Future<ComicDetailSeriesNavSeriesData?> buildSeriesNavData(
  Ref ref,
  Series series,
) async {
  final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  final ComicRepository repo = ref.read(comicRepoProvider);
  final List<String> comicIds = sortedItems
      .map((SeriesItem item) => item.comicId)
      .toList(growable: false);
  final Map<String, String> titlesById = await resolveComicTitlesForDisplay(
    repo,
    comicIds,
  );
  final List<ComicDetailSeriesNavItem> items = <ComicDetailSeriesNavItem>[
    for (int index = 0; index < sortedItems.length; index++)
      ComicDetailSeriesNavItem(
        displayIndex: index + 1,
        comicId: sortedItems[index].comicId,
        title: titlesById[sortedItems[index].comicId]!,
      ),
  ];
  if (items.isEmpty) {
    return null;
  }
  return ComicDetailSeriesNavSeriesData(
    seriesId: series.id,
    seriesName: series.name,
    items: items,
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
  final SeriesReadingContext? ctx = await ref
      .read(seriesRepoProvider)
      .getReadingContextByComicId(comicId);
  if (ctx == null) {
    return const ComicDetailSeriesNavNone();
  }

  final ComicDetailSeriesNavSeriesData? seriesData = await ref.watch(
    comicDetailSeriesNavForSeriesProvider(ctx.seriesId).future,
  );
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
