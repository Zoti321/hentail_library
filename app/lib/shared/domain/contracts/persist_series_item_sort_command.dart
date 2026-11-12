import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';

typedef PersistSeriesItemSortCommand = Future<bool> Function({
  required String comicId,
  required SeriesItemMembership seed,
  required double sortOrder,
  required bool draftLocked,
});
