import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/src/rust/api/series.dart' as rust;

Series mapRustSeries(rust.SeriesDto dto) {
  return Series(
    name: dto.name,
    items: dto.items.map(mapRustSeriesItem).toList(),
  );
}

SeriesItem mapRustSeriesItem(rust.SeriesItemDto dto) {
  return SeriesItem(comicId: dto.comicId, order: dto.sortOrder);
}
