import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_prefer_library_root_series.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_filters_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 每个用例从空偏好开始：SharedPreferences 的 mock 存储按 isolate 复用，
  // 不重置会把上一个用例写入的键带进来。
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

  test('未落盘时四个维度全部取默认值', () async {
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
    expect(
      state.preferLibraryRootSeries,
      LibraryPreferLibraryRootSeries.defaultValue,
    );
    expect(state.sortOption, kLibraryDefaultSeriesSortOption);
  });

  test('每个维度写回自己的键', () async {
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
        .setPreferLibraryRootSeries(false);
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
    expect(prefs.getBool(LibraryPreferLibraryRootSeries.storageKey), false);
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
        .setSerializationStatusFilter(LibrarySerializationStatusFilter.ongoing);
    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setPreferLibraryRootSeries(false);
    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setSortField(LibrarySeriesSortField.comicCount);

    await container.read(librarySeriesFiltersProvider.notifier).resetAll();

    expect(await readState(container), LibrarySeriesFiltersState.defaults);
    expect(prefs.containsKey(kLibrarySeriesAgeRestrictionStorageKey), false);
    expect(
      prefs.containsKey(LibrarySerializationStatusFilter.storageKey),
      false,
    );
    expect(prefs.containsKey(LibraryPreferLibraryRootSeries.storageKey), false);
    expect(prefs.containsKey('library_sort_series'), false);
  });

  test('查询 filter 由当前筛选与关键词派生', () async {
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
        .setPreferLibraryRootSeries(false);

    final LibrarySeriesFilter filter = container.read(
      librarySeriesFiltersQueryProvider,
    );

    expect(filter.showR18, true);
    expect(filter.r18Only, true);
    expect(filter.serializationStatus, 'ongoing');
    expect(filter.preferLibraryRootSeries, false);
  });

  test('是否自定义由状态派生，四个维度各自独立判定', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    await readState(container);

    expect(container.read(librarySeriesFiltersIsCustomizedProvider), false);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setAgeRestriction(LibraryAgeRestrictionFilter.allAges);
    expect(container.read(librarySeriesFiltersIsCustomizedProvider), true);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setAgeRestriction(LibraryAgeRestrictionFilter.unrestricted);
    expect(container.read(librarySeriesFiltersIsCustomizedProvider), false);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setPreferLibraryRootSeries(false);
    expect(container.read(librarySeriesFiltersIsCustomizedProvider), true);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setPreferLibraryRootSeries(true);
    expect(container.read(librarySeriesFiltersIsCustomizedProvider), false);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setSerializationStatusFilter(LibrarySerializationStatusFilter.ongoing);
    expect(container.read(librarySeriesFiltersIsCustomizedProvider), true);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setSerializationStatusFilter(
          LibrarySerializationStatusFilter.unrestricted,
        );
    expect(container.read(librarySeriesFiltersIsCustomizedProvider), false);

    await container
        .read(librarySeriesFiltersProvider.notifier)
        .setSortField(LibrarySeriesSortField.comicCount);
    expect(container.read(librarySeriesFiltersIsCustomizedProvider), true);
  });

  group('decodeLibrarySeriesSortOption', () {
    test('maps legacy title field to name', () {
      final LibrarySeriesSortOption option = decodeLibrarySeriesSortOption(
        'title,true',
      );

      expect(option.field, LibrarySeriesSortField.name);
      expect(option.descending, isTrue);
    });

    test('decodes new series sort fields', () {
      final LibrarySeriesSortOption option = decodeLibrarySeriesSortOption(
        'comicCount,false',
      );

      expect(option.field, LibrarySeriesSortField.comicCount);
      expect(option.descending, isFalse);
    });

    test('decodes random sort field', () {
      final LibrarySeriesSortOption option = decodeLibrarySeriesSortOption(
        'random,true',
      );

      expect(option.field, LibrarySeriesSortField.random);
      expect(option.descending, isTrue);
    });
  });
}
