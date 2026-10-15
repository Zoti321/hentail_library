import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'selecting readAt for the first time defaults to descending, then toggles',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(libraryTabSortProvider.future);

      await container
          .read(libraryTabSortProvider.notifier)
          .setComicSortField(LibraryComicSortField.readAt);

      LibraryComicSortOption sort = (await container.read(
        libraryTabSortProvider.future,
      )).comics;
      expect(sort.field, LibraryComicSortField.readAt);
      expect(sort.descending, isTrue);

      await container
          .read(libraryTabSortProvider.notifier)
          .setComicSortField(LibraryComicSortField.readAt);

      sort = (await container.read(libraryTabSortProvider.future)).comics;
      expect(sort.field, LibraryComicSortField.readAt);
      expect(sort.descending, isFalse);
    },
  );

  test(
    'selecting a non-readAt field for the first time still defaults to ascending',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(libraryTabSortProvider.future);

      await container
          .read(libraryTabSortProvider.notifier)
          .setComicSortField(LibraryComicSortField.createdAt);

      final LibraryComicSortOption sort = (await container.read(
        libraryTabSortProvider.future,
      )).comics;
      expect(sort.field, LibraryComicSortField.createdAt);
      expect(sort.descending, isFalse);
    },
  );
}
