import 'package:hentai_library/features/comic/domain/comic_display_title.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/shared/di/series_reading_context_providers.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/comic/di/comic_repository_providers.dart';

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

/// 漫画详情「系列上一卷 / 下一卷」（#490）。
///
/// 只消费 series owner 的 [SeriesReadingContext] 事实（成员顺序 + 当前下标），
/// 标题仍由 comic 自有 `ComicLookupRepository` 解析；comic 不持有 Series 类型。
/// 刷新信号由 `SeriesReadingContextPort` 的实现决定（series 侧随库 revision 重算）。
@Riverpod(keepAlive: true)
Future<ComicDetailSeriesNavResult> comicDetailSeriesNav(
  Ref ref,
  String comicId,
) async {
  final SeriesReadingContext? context = await ref
      .read(seriesReadingContextPortProvider)
      .getReadingContextByComicId(comicId);
  if (context == null || context.orderedComicIds.isEmpty) {
    return const ComicDetailSeriesNavNone();
  }

  final List<String> comicIds = context.orderedComicIds;
  final int currentIndex = comicIds.indexOf(comicId);
  if (currentIndex < 0) {
    return const ComicDetailSeriesNavNone();
  }

  final ComicLookupRepository repo = ref.read(comicLookupRepositoryProvider);
  final Map<String, String> titlesById = await resolveComicTitlesForDisplay(
    repo,
    comicIds,
  );

  return ComicDetailSeriesNavReady(
    ComicDetailSeriesNavData(
      seriesId: context.seriesId,
      seriesName: context.seriesName,
      items: <ComicDetailSeriesNavItem>[
        for (int index = 0; index < comicIds.length; index++)
          ComicDetailSeriesNavItem(
            displayIndex: index + 1,
            comicId: comicIds[index],
            title:
                titlesById[comicIds[index]] ??
                comicTitleFallbackForDisplay(comicIds[index]),
          ),
      ],
      currentIndex: currentIndex,
    ),
  );
}
