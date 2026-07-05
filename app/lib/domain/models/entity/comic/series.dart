import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';

part 'series.freezed.dart';

/// 系列聚合：由 Library sync 根据文件夹结构自动生成。
@freezed
abstract class Series with _$Series {
  factory Series({
    required String id,
    required String name,
    required String folderPath,
    @Default(SerializationStatus.unknown) SerializationStatus serializationStatus,
    int? totalCount,
    @Default(<SeriesItem>[]) List<SeriesItem> items,
  }) = _Series;

  Series._();

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

  bool hasR18Comic({required Map<String, Comic> comicsById}) {
    for (final SeriesItem item in items) {
      final Comic? comic = comicsById[item.comicId];
      if (comic != null && comic.contentRating == ContentRating.r18) {
        return true;
      }
    }
    return false;
  }

  String? get progressLabel {
    final int? planned = totalCount;
    if (planned == null || planned <= 0) {
      return null;
    }
    return '${items.length} / $planned';
  }
}
