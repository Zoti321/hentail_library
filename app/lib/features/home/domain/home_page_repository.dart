import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

abstract class HomePageRepository {
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18});

  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5({
    required bool excludeR18,
  });

  Stream<List<HomeLibraryAlert>> watchHomeLibraryAlerts();

  Stream<List<HomeLibraryStat>> watchLibraryStats({required bool excludeR18});

  Stream<List<HomeRecentlyAddedEntry>> watchRecentlyAddedOnHome({
    required bool excludeR18,
  });

  Future<LibraryProbeResult> probeLibrary({
    required String libraryId,
    String? password,
  });
}
