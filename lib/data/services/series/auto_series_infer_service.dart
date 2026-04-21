import 'package:hentai_library/data/services/series/comic_title_to_series_item_mapping.dart';

export 'comic_title_to_series_item_mapping.dart';

/// 参与推断的单本漫画（comicId + 可见标题）。
typedef ComicTitleInput = ({String comicId, String title});

/// 推断组内一条漫画（已按卷序、comicId 排序）。
typedef InferredVolumeEntry = ({String comicId, int volumeIndex});

/// 同一系列基名下一组可写入系列的漫画。
typedef InferredSeriesGroup = ({
  String seriesName,
  List<InferredVolumeEntry> entries,
});

/// 将已映射的标题按系列基名分桶，过滤小组并排序（无 I/O）。
final class InferredSeriesGrouper {
  const InferredSeriesGrouper();

  /// 对 [comics] 逐条用 [titleMapping] 解析；仅保留每组至少 [minComicsPerGroup] 条。
  List<InferredSeriesGroup> build(
    Iterable<ComicTitleInput> comics,
    ComicTitleToSeriesItemMapping titleMapping, {
    int minComicsPerGroup = 2,
  }) {
    final Map<String, List<InferredVolumeEntry>> byBase =
        <String, List<InferredVolumeEntry>>{};
    for (final ComicTitleInput c in comics) {
      final MappedSeriesVolume? parsed =
          titleMapping.mapComicTitleToSeriesVolume(c.title);
      if (parsed == null) {
        continue;
      }
      final List<InferredVolumeEntry> bucket = byBase.putIfAbsent(
        parsed.seriesName,
        () => <InferredVolumeEntry>[],
      );
      bucket.add((comicId: c.comicId, volumeIndex: parsed.volumeIndex));
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
      out.add((seriesName: e.key, entries: e.value));
    }
    out.sort(
      (InferredSeriesGroup a, InferredSeriesGroup b) =>
          a.seriesName.compareTo(b.seriesName),
    );
    return out;
  }
}

/// 自动从漫画标题推断系列：编排「单标题解析」与「按基名分组」两步（无 I/O）。
///
/// 对外请只 `import` 本文件；其通过 [export] 再导出 [ComicTitleToSeriesItemMapping] 与 [MappedSeriesVolume]。
final class AutoSeriesInferService {
  const AutoSeriesInferService({
    ComicTitleToSeriesItemMapping titleMapping =
        const ComicTitleToSeriesItemMapping(),
    InferredSeriesGrouper grouper = const InferredSeriesGrouper(),
  }) : _titleMapping = titleMapping,
       _grouper = grouper;

  final ComicTitleToSeriesItemMapping _titleMapping;
  final InferredSeriesGrouper _grouper;

  /// 返回可按卷序写入 [Series] 的推断组。
  ///
  /// 1) 对每个标题委托 [ComicTitleToSeriesItemMapping]：去 Comic Market 前缀，再按规则得到基名与卷序。
  /// 2) 委托 [InferredSeriesGrouper]：按基名分桶、过滤、组内与组间排序。
  List<InferredSeriesGroup> inferGroups(
    Iterable<ComicTitleInput> comics, {
    int minComicsPerGroup = 2,
  }) {
    return _grouper.build(
      comics,
      _titleMapping,
      minComicsPerGroup: minComicsPerGroup,
    );
  }
}
