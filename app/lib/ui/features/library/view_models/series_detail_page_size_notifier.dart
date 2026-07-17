import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'series_detail_page_size_notifier.g.dart';

@Riverpod(keepAlive: true)
class SeriesDetailPageSizeNotifier extends _$SeriesDetailPageSizeNotifier {
  static const String _storageKey = 'series_detail_page_size';

  @override
  Future<int> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return normalizeLibraryPageSize(prefs.getInt(_storageKey));
  }

  Future<void> setPageSize(int pageSize) async {
    final int normalized = normalizeLibraryPageSize(pageSize);
    state = AsyncData<int>(normalized);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (normalized == kDefaultPageSize) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setInt(_storageKey, normalized);
    }
  }
}
