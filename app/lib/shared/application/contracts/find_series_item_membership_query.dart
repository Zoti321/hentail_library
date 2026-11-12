import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';

typedef FindSeriesItemMembershipQuery = Future<SeriesItemMembership?> Function(
  String comicId,
);
