import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _storageKey = 'series_detail_page_size';

Future<int> loadSeriesDetailPageSize() async => normalizeLibraryPageSize(
  (await SharedPreferences.getInstance()).getInt(_storageKey),
);

Future<void> saveSeriesDetailPageSize(int pageSize) async {
  final normalized = normalizeLibraryPageSize(pageSize);
  final prefs = await SharedPreferences.getInstance();
  if (normalized == kDefaultPageSize) {
    await prefs.remove(_storageKey);
  } else {
    await prefs.setInt(_storageKey, normalized);
  }
}
