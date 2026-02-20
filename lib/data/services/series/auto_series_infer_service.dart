import 'package:hentai_library/data/services/series/comic_title_to_series_item_mapping.dart';

export 'comic_title_to_series_item_mapping.dart';

/// 参与推断的单本漫画（comicId + 可见标题）。
typedef ComicTitleInput = ({String comicId, String title});

/// 推断组内一条漫画（已按卷序、comicId 排序）。
typedef InferredVolumeEntry = ({String comicId, num volumeSortKey});

/// 同一系列基名下一组可写入系列的漫画。
typedef InferredSeriesGroup = ({
  String seriesName,
  List<InferredVolumeEntry> entries,
});

/// 仅标题列表推断结果（用于黄金测试与 UI）。
typedef InferredSeriesFromTitlesResult = ({
  String seriesName,
  Map<String, int> indexByTitle,
});

typedef _ResolvedLine = ({
  String comicId,
  String originalTitle,
  String clusterKey,
  String seriesDisplayName,
  num volumeSortKey,
});

/// 批量解析：隐式卷 1、総集編卷号、聚类键合并。
final class _SeriesBatchInferenceResolver {
  const _SeriesBatchInferenceResolver({
    ComicTitleToSeriesItemMapping titleMapping =
        const ComicTitleToSeriesItemMapping(),
  }) : _titleMapping = titleMapping;

  final ComicTitleToSeriesItemMapping _titleMapping;

  List<_ResolvedLine> resolve(Iterable<ComicTitleInput> comics) {
    final List<ComicTitleInput> list = comics.toList();
    final List<_ResolvedLine?> slots = List<_ResolvedLine?>.filled(
      list.length,
      null,
    );
    final Map<String, String> clusterKeyToDisplay = <String, String>{};
    for (int i = 0; i < list.length; i++) {
      final ComicTitleInput c = list[i];
      final String normalized = SeriesTitleClustering.normalizeTitleText(c.title);
      final MappedSeriesVolume? p =
          _titleMapping.mapComicTitleToSeriesVolume(normalized);
      if (p != null) {
        final String key = SeriesTitleClustering.clusterKeyFromSeriesName(
          p.seriesName,
        );
        clusterKeyToDisplay.putIfAbsent(key, () => key);
        slots[i] = (
          comicId: c.comicId,
          originalTitle: c.title,
          clusterKey: key,
          seriesDisplayName: key,
          volumeSortKey: p.volumeSortKey,
        );
      }
    }
    for (int i = 0; i < list.length; i++) {
      if (slots[i] != null) {
        continue;
      }
      final ComicTitleInput c = list[i];
      final String stripped = ComicTitleToSeriesItemMapping.stripComiketPrefixes(
        c.title.trim(),
      );
      final bool isSoushuuhen =
          SeriesTitleClustering.endsWithSoushuuhen(stripped);
      if (isSoushuuhen) {
        final String key =
            SeriesTitleClustering.clusterKeyFromFullTitle(c.title);
        final String? display = clusterKeyToDisplay[key];
        if (display != null) {
          slots[i] = (
            comicId: c.comicId,
            originalTitle: c.title,
            clusterKey: key,
            seriesDisplayName: display,
            volumeSortKey: -1,
          );
        }
      }
    }
    for (int i = 0; i < list.length; i++) {
      if (slots[i] != null) {
        continue;
      }
      final ComicTitleInput c = list[i];
      final String key =
          SeriesTitleClustering.clusterKeyFromFullTitle(c.title);
      final String? display = clusterKeyToDisplay[key];
      if (display == null) {
        continue;
      }
      slots[i] = (
        comicId: c.comicId,
        originalTitle: c.title,
        clusterKey: key,
        seriesDisplayName: display,
        volumeSortKey: 1,
      );
    }
    final List<_ResolvedLine> partial = <_ResolvedLine>[];
    for (int i = 0; i < list.length; i++) {
      final _ResolvedLine? s = slots[i];
      if (s != null) {
        partial.add(s);
      }
    }
    final Map<String, List<_ResolvedLine>> byKey =
        <String, List<_ResolvedLine>>{};
    for (final _ResolvedLine line in partial) {
      if (line.volumeSortKey == -1) {
        continue;
      }
      byKey.putIfAbsent(line.clusterKey, () => <_ResolvedLine>[]).add(line);
    }
    for (int i = 0; i < list.length; i++) {
      final _ResolvedLine? s = slots[i];
      if (s == null || s.volumeSortKey != -1) {
        continue;
      }
      final List<_ResolvedLine>? bucket = byKey[s.clusterKey];
      if (bucket == null || bucket.isEmpty) {
        continue;
      }
      num maxVol = 0;
      for (final _ResolvedLine e in bucket) {
        if (e.volumeSortKey > maxVol) {
          maxVol = e.volumeSortKey;
        }
      }
      final num nextVol = maxVol + 1;
      slots[i] = (
        comicId: s.comicId,
        originalTitle: s.originalTitle,
        clusterKey: s.clusterKey,
        seriesDisplayName: s.seriesDisplayName,
        volumeSortKey: nextVol,
      );
    }
    final List<_ResolvedLine> out = <_ResolvedLine>[];
    for (int i = 0; i < list.length; i++) {
      final _ResolvedLine? s = slots[i];
      if (s != null) {
        out.add(s);
      }
    }
    return out;
  }
}

/// 将已映射的标题按系列基名分桶，过滤小组并排序（无 I/O）。
final class InferredSeriesGrouper {
  const InferredSeriesGrouper();

  /// 对 [comics] 逐条用 [titleMapping] 与批量解析；仅保留每组至少 [minComicsPerGroup] 条。
  List<InferredSeriesGroup> build(
    Iterable<ComicTitleInput> comics,
    ComicTitleToSeriesItemMapping titleMapping, {
    int minComicsPerGroup = 2,
  }) {
    final _SeriesBatchInferenceResolver resolver = _SeriesBatchInferenceResolver(
      titleMapping: titleMapping,
    );
    final List<_ResolvedLine> resolved = resolver.resolve(comics);
    final Map<String, List<InferredVolumeEntry>> byBase =
        <String, List<InferredVolumeEntry>>{};
    final Map<String, String> baseToDisplay = <String, String>{};
    for (final _ResolvedLine line in resolved) {
      final List<InferredVolumeEntry> bucket = byBase.putIfAbsent(
        line.clusterKey,
        () => <InferredVolumeEntry>[],
      );
      bucket.add(
        (comicId: line.comicId, volumeSortKey: line.volumeSortKey),
      );
      baseToDisplay[line.clusterKey] = line.seriesDisplayName;
    }
    final List<InferredSeriesGroup> out = <InferredSeriesGroup>[];
    for (final MapEntry<String, List<InferredVolumeEntry>> e
        in byBase.entries) {
      if (e.value.length < minComicsPerGroup) {
        continue;
      }
      e.value.sort((InferredVolumeEntry a, InferredVolumeEntry b) {
        final int byVol = InferredSeriesGrouper.compareVolumeSortKey(
          a.volumeSortKey,
          b.volumeSortKey,
        );
        if (byVol != 0) {
          return byVol;
        }
        return a.comicId.compareTo(b.comicId);
      });
      final String displayName = baseToDisplay[e.key] ?? e.key;
      out.add((seriesName: displayName, entries: e.value));
    }
    out.sort(
      (InferredSeriesGroup a, InferredSeriesGroup b) =>
          a.seriesName.compareTo(b.seriesName),
    );
    return out;
  }

  static int compareVolumeSortKey(num a, num b) {
    if (a is int && b is int) {
      return a.compareTo(b);
    }
    return a.toDouble().compareTo(b.toDouble());
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

  /// 对一批标题（无 comicId）推断单一系列；若无法形成一组则返回 null。
  ///
  /// [indexByTitle] 的键为去掉 Comic Market 前缀后的可见标题（与黄金用例一致）。
  /// 若组内存在非整数卷序键，则输出稠密名次 1..n；否则输出稀疏卷号（与解析键一致）。
  InferredSeriesFromTitlesResult? inferSeriesFromTitles(
    List<String> titles, {
    int minTitlesPerSeries = 2,
  }) {
    final List<ComicTitleInput> comics = <ComicTitleInput>[];
    for (int i = 0; i < titles.length; i++) {
      comics.add((comicId: '$i', title: titles[i]));
    }
    final List<InferredSeriesGroup> groups = inferGroups(
      comics,
      minComicsPerGroup: minTitlesPerSeries,
    );
    if (groups.length != 1) {
      return null;
    }
    final InferredSeriesGroup g = groups.first;
    final bool useDenseRank = g.entries.any((InferredVolumeEntry e) {
      final double d = e.volumeSortKey.toDouble();
      return d != d.floorToDouble();
    });
    final List<InferredVolumeEntry> sorted = List<InferredVolumeEntry>.of(
      g.entries,
    )..sort((InferredVolumeEntry a, InferredVolumeEntry b) {
        final int byVol = InferredSeriesGrouper.compareVolumeSortKey(
          a.volumeSortKey,
          b.volumeSortKey,
        );
        if (byVol != 0) {
          return byVol;
        }
        return a.comicId.compareTo(b.comicId);
      });
    final Map<String, int> indexByTitle = <String, int>{};
    if (useDenseRank) {
      int rank = 1;
      for (final InferredVolumeEntry e in sorted) {
        final int idx = int.parse(e.comicId);
        final String key = _indexKeyForTitle(titles[idx]);
        indexByTitle[key] = rank;
        rank++;
      }
    } else {
      for (final InferredVolumeEntry e in sorted) {
        final int idx = int.parse(e.comicId);
        final String key = _indexKeyForTitle(titles[idx]);
        indexByTitle[key] = e.volumeSortKey.floor();
      }
    }
    return (seriesName: g.seriesName, indexByTitle: indexByTitle);
  }

  /// 与黄金用例一致：去掉 Comic Market 前缀；保留原文中的 `...` / `…` 等写法。
  static String _indexKeyForTitle(String title) {
    return ComicTitleToSeriesItemMapping.stripComiketPrefixes(title.trim());
  }
}
