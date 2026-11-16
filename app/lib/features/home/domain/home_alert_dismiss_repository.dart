import 'package:hentai_library/features/home/domain/home_alert_dismissal.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

abstract interface class HomeAlertDismissRepository {
  Future<Map<String, HomeAlertDismissEntry>> load();
  Future<void> dismiss(HomeLibraryAlert alert, DateTime dismissedAt);
  Future<void> clearForLibrary(String libraryId);
}
