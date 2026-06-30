import 'package:hentai_library/data/database/database.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';

class SeriesDbMapper {
  const SeriesDbMapper();
}

extension DbSeriesItemToEntity on DbSeriesItem {
  SeriesItem toEntity() {
    return SeriesItem(comicId: comicId, order: sortOrder);
  }
}
