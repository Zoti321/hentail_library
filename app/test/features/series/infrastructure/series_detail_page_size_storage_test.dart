import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/series/infrastructure/series_detail_page_size_storage.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads existing key, normalizes legacy values and removes only the default key', () async {
    SharedPreferences.setMockInitialValues({
      'series_detail_page_size': 500,
      'unrelated': true,
    });
    expect(await loadSeriesDetailPageSize(), 200);
    await saveSeriesDetailPageSize(100);
    expect(await loadSeriesDetailPageSize(), 100);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('series_detail_page_size'), 100);
    await saveSeriesDetailPageSize(kDefaultPageSize);
    expect(prefs.containsKey('series_detail_page_size'), isFalse);
    expect(prefs.getBool('unrelated'), isTrue);
    expect(await loadSeriesDetailPageSize(), kDefaultPageSize);
  });

  test('invalid saved values use the default', () async {
    SharedPreferences.setMockInitialValues({'series_detail_page_size': -1});
    expect(await loadSeriesDetailPageSize(), kDefaultPageSize);
  });
}
