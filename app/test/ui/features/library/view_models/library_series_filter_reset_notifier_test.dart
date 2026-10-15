import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_prefer_library_root_series.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_prefer_library_root_series_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_serialization_status_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_filter_reset_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'series resetAll clears serialization, age, prefer-root, and sort',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(librarySerializationStatusFilterProvider.future);
      await container.read(libraryAgeRestrictionFilterProvider.future);
      await container.read(libraryPreferLibraryRootSeriesProvider.future);
      await container.read(libraryTabSortProvider.future);

      await container
          .read(librarySerializationStatusFilterProvider.notifier)
          .setFilter(LibrarySerializationStatusFilter.ongoing);
      await container
          .read(libraryAgeRestrictionFilterProvider.notifier)
          .setFilter(
            LibraryDisplayTarget.series,
            LibraryAgeRestrictionFilter.r18Only,
          );
      await container
          .read(libraryPreferLibraryRootSeriesProvider.notifier)
          .setEnabled(false);
      await container
          .read(libraryTabSortProvider.notifier)
          .setSeriesSortField(LibrarySeriesSortField.comicCount);

      await container
          .read(librarySeriesFilterResetProvider.notifier)
          .resetAll();

      expect(
        await container.read(librarySerializationStatusFilterProvider.future),
        LibrarySerializationStatusFilter.unrestricted,
      );
      expect(
        (await container.read(
          libraryAgeRestrictionFilterProvider.future,
        )).series,
        LibraryAgeRestrictionFilter.unrestricted,
      );
      expect(
        await container.read(libraryPreferLibraryRootSeriesProvider.future),
        LibraryPreferLibraryRootSeries.defaultValue,
      );
      final LibrarySeriesSortOption sort = (await container.read(
        libraryTabSortProvider.future,
      )).series;
      expect(sort.field, kLibraryDefaultSeriesSortOption.field);
      expect(sort.descending, kLibraryDefaultSeriesSortOption.descending);
    },
  );
}
