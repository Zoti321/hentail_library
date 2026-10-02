import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_expand_by_series.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_needs_metadata_only.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_filter_reset_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_expand_by_series_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_needs_metadata_only_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'comics resetAll restores age, expand-by-series, needs metadata, and sort',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(libraryAgeRestrictionFilterProvider.future);
      await container.read(libraryExpandBySeriesProvider.future);
      await container.read(libraryNeedsMetadataOnlyProvider.future);
      await container.read(libraryTabSortProvider.future);

      await container
          .read(libraryAgeRestrictionFilterProvider.notifier)
          .setFilter(
            LibraryDisplayTarget.comics,
            LibraryAgeRestrictionFilter.r18Only,
          );
      await container
          .read(libraryExpandBySeriesProvider.notifier)
          .setEnabled(false);
      await container
          .read(libraryNeedsMetadataOnlyProvider.notifier)
          .setEnabled(true);
      await container
          .read(libraryTabSortProvider.notifier)
          .setComicSortField(LibraryComicSortField.createdAt);

      await container
          .read(libraryComicsFilterResetProvider.notifier)
          .resetAll();

      expect(
        (await container.read(
          libraryAgeRestrictionFilterProvider.future,
        )).comics,
        LibraryAgeRestrictionFilter.unrestricted,
      );
      expect(
        await container.read(libraryExpandBySeriesProvider.future),
        LibraryExpandBySeries.defaultValue,
      );
      expect(
        await container.read(libraryNeedsMetadataOnlyProvider.future),
        LibraryNeedsMetadataOnly.defaultValue,
      );
      final LibraryComicSortOption sort = (await container.read(
        libraryTabSortProvider.future,
      )).comics;
      expect(sort.field, kLibraryDefaultSortOption.field);
      expect(sort.descending, kLibraryDefaultSortOption.descending);
    },
  );

  test('needs metadata preference persists across containers', () async {
    final ProviderContainer first = ProviderContainer();
    await first.read(libraryNeedsMetadataOnlyProvider.future);
    await first
        .read(libraryNeedsMetadataOnlyProvider.notifier)
        .setEnabled(true);
    first.dispose();

    final ProviderContainer second = ProviderContainer();
    addTearDown(second.dispose);
    expect(await second.read(libraryNeedsMetadataOnlyProvider.future), isTrue);
  });
}
