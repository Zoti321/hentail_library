import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/src/rust/api/home.dart' as rust;

class HomePageRepositoryImpl implements HomePageRepository {
  HomePageRepositoryImpl(this._homePageDao);

  final HomePageDao _homePageDao;

  @override
  Stream<HomePageCounts> watchHomePageCounts() {
    return rust.watchHomePageCountsFrb(excludeR18: false).map(_mapCounts);
  }

  @override
  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5({
    required bool excludeR18,
  }) {
    if (excludeR18) {
      return _homePageDao.watchContinueReadingTop5Healthy();
    }
    return _homePageDao.watchContinueReadingTop5();
  }

  @override
  Stream<Map<String, int>> watchHomeSeriesComicOrderMap() {
    return _homePageDao.watchHomeSeriesComicOrderMap();
  }

  HomePageCounts _mapCounts(rust.HomePageCountsDto dto) {
    return HomePageCounts(
      comicCount: dto.comicCount,
      tagCount: dto.tagCount,
      seriesCount: dto.seriesCount,
      readingRecordCount: dto.readingRecordCount,
    );
  }
}
