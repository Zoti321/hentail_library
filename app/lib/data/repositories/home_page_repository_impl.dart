import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/src/rust/api/home.dart' as rust;

class HomePageRepositoryImpl implements HomePageRepository {
  const HomePageRepositoryImpl();

  @override
  Stream<HomePageCounts> watchHomePageCounts() {
    return guardFrbStream(
      () => rust.watchHomePageCountsFrb(excludeR18: false).map(_mapCounts),
      fallbackMessage: '读取首页统计失败',
    );
  }

  @override
  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5({
    required bool excludeR18,
  }) {
    return guardFrbStream(
      () => rust
          .watchContinueReadingTop5Frb(excludeR18: excludeR18)
          .map(
            (List<rust.HomeContinueReadingDto> rows) =>
                rows.map(_mapContinueReading).toList(),
          ),
      fallbackMessage: '读取继续阅读失败',
    );
  }

  HomePageCounts _mapCounts(rust.HomePageCountsDto dto) {
    return HomePageCounts(
      comicCount: dto.comicCount,
      tagCount: dto.tagCount,
      seriesCount: dto.seriesCount,
      readingRecordCount: dto.readingRecordCount,
    );
  }

  HomeContinueReadingEntry _mapContinueReading(
    rust.HomeContinueReadingDto dto,
  ) {
    return HomeContinueReadingEntry(
      comicId: dto.comicId,
      title: dto.title,
      lastReadTime: DateTime.fromMillisecondsSinceEpoch(dto.lastReadTimeMs),
      pageIndex: dto.pageIndex,
    );
  }
}
