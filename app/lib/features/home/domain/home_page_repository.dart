import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

abstract class HomePageRepository {
  Stream<List<HomeLibraryAlert>> watchHomeLibraryAlerts();

  Stream<List<HomeLibraryStat>> watchLibraryStats({required bool excludeR18});
}
