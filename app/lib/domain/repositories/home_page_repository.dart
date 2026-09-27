import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';

abstract class HomePageRepository {
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18});

  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5({
    required bool excludeR18,
  });

  Stream<List<HomeLibraryAlert>> watchHomeLibraryAlerts();

  Stream<List<HomeRecentlyAddedEntry>> watchRecentlyAddedOnHome({
    required bool excludeR18,
  });

  Future<LibraryProbeResult> probeLibrary({
    required String libraryId,
    String? password,
  });
}
