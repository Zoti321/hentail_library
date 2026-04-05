import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';

part 'series.freezed.dart';

/// 系列聚合（独立于 Comic，本质上维护归属与顺序）。
@freezed
abstract class Series with _$Series {
  factory Series({
    required String name,
    @Default(<SeriesItem>[]) List<SeriesItem> items,
  }) = _Series;

  Series._();

  /// Item used for series cover: largest [SeriesItem.order]; ties break by
  /// lexicographically smaller [SeriesItem.comicId].
  SeriesItem? get coverItem {
    final List<SeriesItem> list = items;
    if (list.isEmpty) {
      return null;
    }
    SeriesItem best = list.first;
    for (int i = 1; i < list.length; i++) {
      final SeriesItem item = list[i];
      if (item.order > best.order) {
        best = item;
      } else if (item.order == best.order &&
          item.comicId.compareTo(best.comicId) < 0) {
        best = item;
      }
    }
    return best;
  }

  bool containsComic(String comicId) => items.any((e) => e.comicId == comicId);

  /// 将漫画加入系列（若已存在则更新其顺序）。
  Series upsertComic(String comicId, {required int order}) {
    final next = <SeriesItem>[
      for (final i in items)
        if (i.comicId != comicId) i,
      SeriesItem(comicId: comicId, order: order),
    ]..sort((a, b) => a.order.compareTo(b.order));
    return copyWith(items: next);
  }

  Series removeComic(String comicId) {
    return copyWith(items: items.where((e) => e.comicId != comicId).toList());
  }
}
