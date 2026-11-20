import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/repositories/image_set_browse_preferences_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ImageSetBrowsePreferencesRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'library_sort_comics': 'title',
    });
    repository = const ImageSetBrowsePreferencesRepositoryImpl();
  });

  test('load returns defaults when empty', () async {
    expect(await repository.load(), ImageSetBrowsePreferences.defaults);
  });

  test('round-trips preferences without touching comic keys', () async {
    final ImageSetBrowsePreferences saved = ImageSetBrowsePreferences(
      authors: const ImageSetFacetFilter(any: <String>{'A'}),
      tags: const ImageSetFacetFilter(unassigned: true),
      carrierShape: ImageSetCarrierShape.rootArchive,
      requireImages: true,
      sort: const ImageSetSortOption(
        field: ImageSetSortField.imageCount,
        descending: true,
      ),
      grouping: ImageSetGrouping.byAuthor,
      pageSize: 100,
    );
    await repository.save(saved);

    expect(await repository.load(), saved);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('library_sort_comics'), 'title');
    expect(prefs.getInt(kImageSetBrowsePageSizeKey), 100);

    await repository.reset();
    expect(await repository.load(), ImageSetBrowsePreferences.defaults);
    expect(prefs.getString('library_sort_comics'), 'title');
  });

  test('normalizes invalid page size to default option', () async {
    await repository.save(
      const ImageSetBrowsePreferences(pageSize: 7),
    );
    expect((await repository.load()).pageSize, 50);
  });
}
