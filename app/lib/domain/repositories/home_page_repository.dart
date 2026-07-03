import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';

abstract class HomePageRepository {
  Stream<HomePageCounts> watchHomePageCounts();

  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5({
    required bool excludeR18,
  });
}
