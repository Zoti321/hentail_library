import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/series/domain/library_series_grouping.dart';
import 'package:hentai_library/features/series/domain/library_series_filter.dart';
import 'package:hentai_library/features/series/domain/library_series_sort_option.dart';
import 'package:hentai_library/features/series/domain/library_serialization_status_filter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<SharedPreferences> mockPrefs() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return SharedPreferences.getInstance();
  }

  Future<LibrarySeriesFiltersState> readState(ProviderContainer container) {
    return container.read(librarySeriesFiltersProvider.future);
  }

  test('未落盘时维度全部取默认值', () async {
    await mockPrefs();
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final LibrarySeriesFiltersState state = await readState(container);

    expect(state, LibrarySeriesFiltersState.defaults);
    expect(state.ageRestriction, LibraryAgeRestrictionFilter.unrestricted);
    expect(
      state.serializationStatusFilter,
      LibrarySerializationStatusFilter.unrestricted,
    );
    expect(state.grouping, LibrarySeriesGrouping.defaultValue);
    expect(state.sortOption, kLibraryDefaultSeriesSortOption);
  });

  test('筛选与分组维度写回自己的键', () async {
    final SharedPreferences prefs = await mockPrefs();
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    await readState(container);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setAgeRestriction(LibraryAgeRestrictionFilter.r18Only);
    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setSerializationStatusFilter(LibrarySerializationStatusFilter.ongoing);
    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setGrouping(LibrarySeriesGrouping.bySerializationStatus);
    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setSortField(LibrarySeriesSortField.comicCount);

    expect(
      prefs.getString(kLibrarySeriesAgeRestrictionStorageKey),
      LibraryAgeRestrictionFilter.r18Only.name,
    );
    expect(
      prefs.getString(LibrarySerializationStatusFilter.storageKey),
      LibrarySerializationStatusFilter.ongoing.name,
    );
    expect(
      prefs.getString(LibrarySeriesGrouping.storageKey),
      LibrarySeriesGrouping.bySerializationStatus.name,
    );
    expect(prefs.getString('library_sort_series'), 'comicCount,false');
  });

  test('resetAll 清空全部键并恢复默认', () async {
    final SharedPreferences prefs = await mockPrefs();
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    await readState(container);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setAgeRestriction(LibraryAgeRestrictionFilter.r18Only);
    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setGrouping(LibrarySeriesGrouping.bySerializationStatus);
    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setSortField(LibrarySeriesSortField.comicCount);

    await container.read(librarySeriesFiltersProvider.notifier).resetAll();

    expect(await readState(container), LibrarySeriesFiltersState.defaults);
    expect(prefs.containsKey(kLibrarySeriesAgeRestrictionStorageKey), false);
    expect(prefs.containsKey(LibrarySeriesGrouping.storageKey), false);
    expect(prefs.containsKey('library_sort_series'), false);
  });

  test('查询 filter 的 prefer root 来自设置页', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsProvider.overrideWith(
          () => _FixedSettingsNotifier(
            AppSetting(preferLibraryRootSeries: false),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await readState(container);
    await container.read(settingsProvider.future);

    final LibrarySeriesFilter filter = container.read(
      librarySeriesFiltersQueryProvider,
    );

    expect(filter.preferLibraryRootSeries, isFalse);
  });

  group('decodeLibrarySeriesSortOption', () {
    test('maps legacy title field to name', () {
      final LibrarySeriesSortOption option = decodeLibrarySeriesSortOption(
        'title,true',
      );

      expect(option.field, LibrarySeriesSortField.name);
      expect(option.descending, isTrue);
    });
  });
}

class _FixedSettingsNotifier extends SettingsNotifier {
  _FixedSettingsNotifier(this._fixed);

  final AppSetting _fixed;

  @override
  Future<AppSetting> build() async => _fixed;
}
