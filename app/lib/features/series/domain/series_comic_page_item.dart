import 'package:hentai_library/features/comic/public/comic.dart';

/// 系列成员分页读模型（owner @ `features/series/domain/`，ADR-0041）。
typedef SeriesComicPageItem = ({
  Comic comic,
  double sortOrder,
  bool sortOrderLocked,
});
