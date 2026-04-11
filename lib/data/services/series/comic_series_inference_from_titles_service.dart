import 'package:hentai_library/data/services/series/comic_title_to_series_item_mapping.dart';

export 'comic_title_to_series_item_mapping.dart';

/// 推断出的系列内一条漫画（已按卷序、comicId 排序）。
final class InferredVolumeEntry {
  const InferredVolumeEntry({
    required this.comicId,
    required this.volumeIndex,
  });

  final String comicId;
  final int volumeIndex;
}

/// 同一基名下一组可写入系列的漫画。
final class InferredSeriesGroup {
  const InferredSeriesGroup({
    required this.seriesName,
    required this.entries,
  });

  final String seriesName;
  final List<InferredVolumeEntry> entries;
}

/// 从漫画标题解析「基名 + 空白 + 卷号」并分组（无 I/O）。
final class ComicSeriesInferenceFromTitlesService {
  const ComicSeriesInferenceFromTitlesService({
    ComicTitleToSeriesItemMapping titleMapping = const ComicTitleToSeriesItemMapping(),
  }) : _titleMapping = titleMapping;

  final ComicTitleToSeriesItemMapping _titleMapping;

  /// 仅保留「基名」下至少 [minComicsPerGroup] 本（数字卷或 前篇/后篇）的条目。
  List<InferredSeriesGroup> inferGroups(
    Iterable<ComicTitleInput> comics, {
    int minComicsPerGroup = 2,
  }) {
    final Map<String, List<InferredVolumeEntry>> byBase =
        <String, List<InferredVolumeEntry>>{};
    for (final ComicTitleInput c in comics) {
      final MappedSeriesVolume? parsed =
          _titleMapping.mapComicTitleToSeriesVolume(c.title);
      if (parsed == null) {
        continue;
      }
      final List<InferredVolumeEntry> bucket =
          byBase.putIfAbsent(parsed.seriesName, () => <InferredVolumeEntry>[]);
      bucket.add(
        InferredVolumeEntry(
          comicId: c.comicId,
          volumeIndex: parsed.volumeIndex,
        ),
      );
    }
    final List<InferredSeriesGroup> out = <InferredSeriesGroup>[];
    for (final MapEntry<String, List<InferredVolumeEntry>> e
        in byBase.entries) {
      if (e.value.length < minComicsPerGroup) {
        continue;
      }
      e.value.sort((InferredVolumeEntry a, InferredVolumeEntry b) {
        final int byVol = a.volumeIndex.compareTo(b.volumeIndex);
        if (byVol != 0) {
          return byVol;
        }
        return a.comicId.compareTo(b.comicId);
      });
      out.add(InferredSeriesGroup(seriesName: e.key, entries: e.value));
    }
    out.sort(
      (InferredSeriesGroup a, InferredSeriesGroup b) =>
          a.seriesName.compareTo(b.seriesName),
    );
    return out;
  }
}
