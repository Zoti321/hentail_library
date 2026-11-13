import 'package:hentai_library/features/library_admin/infrastructure/library_migration_store_impl.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_migration_store_provider.dart';

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/infrastructure/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/libraries_notifier.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';

class _LegacyFile implements LegacySettingsJsonFile {
  _LegacyFile(this.content);
  String? content;

  @override
  Future<bool> exists() async => content != null;

  @override
  Future<String> readAsString() async => content!;

  @override
  Future<void> delete() async => content = null;
}

class _Libraries implements LibraryRepository {
  String? failUpdateFor;
  final Map<String, List<ResourceFormatCategory>> saved =
      <String, List<ResourceFormatCategory>>{};

  @override
  Future<List<LocalLibrary>> list() async => <LocalLibrary>[
    for (final String id in <String>['local', 'remote'])
      (
        libraryId: id,
        kind: id,
        rootPath: id == 'local' ? '/books' : 'https://example.invalid/books',
        name: id,
        enabledResourceFormatCategories:
            saved[id] ?? ResourceFormatCategory.all,
        username: '',
        allowHttp: false,
        scanOnStartup: false,
        scanInterval: ScanInterval.disabled,
        pinned: true,
        sidebarOrder: 0,
      ),
  ];

  @override
  Future<LocalLibrary> updateResourceFormatCategories({
    required String libraryId,
    required List<ResourceFormatCategory> groups,
  }) async {
    if (libraryId == failUpdateFor) throw StateError('format write failed');
    saved[libraryId] = List<ResourceFormatCategory>.of(groups);
    return (await list()).firstWhere(
      (LocalLibrary lib) => lib.libraryId == libraryId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const List<
    ({
      String name,
      Map<String, Object?> json,
      List<ResourceFormatCategory> expected,
    })
  >
  cases = [
    (name: 'missing', json: {}, expected: ResourceFormatCategory.all),
    (
      name: 'null',
      json: {'enabledFormatGroups': null},
      expected: ResourceFormatCategory.all,
    ),
    (name: 'empty', json: {'enabledFormatGroups': []}, expected: []),
    (
      name: 'non-list',
      json: {'enabledFormatGroups': 'pdf'},
      expected: ResourceFormatCategory.all,
    ),
    (
      name: 'unknown',
      json: {
        'enabledFormatGroups': ['future'],
      },
      expected: ResourceFormatCategory.all,
    ),
    (
      name: 'mixed',
      json: {
        'enabledFormatGroups': ['future', 'pdf'],
      },
      expected: [ResourceFormatCategory.pdf],
    ),
    (
      name: 'canonical order and duplicates',
      json: {
        'enabledFormatGroups': ['archive', 'pdf', 'archive', 'folder'],
      },
      expected: [
        ResourceFormatCategory.folder,
        ResourceFormatCategory.pdf,
        ResourceFormatCategory.archive,
      ],
    ),
  ];

  for (final bool stageFirst in <bool>[false, true]) {
    for (final scenario in cases) {
      test(
        '${stageFirst ? "staged" : "legacy JSON"} ${scenario.name} migrates into every Library',
        () async {
          SharedPreferences.setMockInitialValues(<String, Object>{});
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final AppSettingRepositoryImpl settings = AppSettingRepositoryImpl(
            sharedPreferences: prefs,
            legacySettingsFile: _LegacyFile(jsonEncode(scenario.json)),
          );
          if (stageFirst) {
            await settings.load();
          }
          final _Libraries libraries = _Libraries();
          final ProviderContainer container = ProviderContainer(
            overrides: [
              libraryMigrationStoreProvider.overrideWithValue(
                const LibraryMigrationStoreImpl(),
              ),
              libraryRepoProvider.overrideWithValue(libraries),
              appSettingRepositoryProvider.overrideWithValue(settings),
            ],
          );
          addTearDown(container.dispose);

          await container.read(librariesProvider.future);

          expect(libraries.saved.keys, unorderedEquals(['local', 'remote']));
          expect(libraries.saved['local'], scenario.expected);
          expect(libraries.saved['remote'], scenario.expected);
          expect(
            prefs.getBool('migrated_enabled_format_groups_to_libraries_v1'),
            isTrue,
          );
          if (stageFirst) {
            expect(await settings.peekLegacyResourceFormatPayload(), isNull);
          }
          libraries.saved.clear();
          await container.read(librariesProvider.notifier).refresh();
          expect(
            libraries.saved,
            isEmpty,
            reason: 'The completed migration must not overwrite per-library choices again.',
          );
        },
      );
    }
  }

  test('failed migration retains the staged settings until the next explicit refresh succeeds', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettingRepositoryImpl(
      sharedPreferences: prefs,
      legacySettingsFile: _LegacyFile(
        jsonEncode({
          'enabledFormatGroups': ['pdf'],
        }),
      ),
    );
    await settings.load();
    final libraries = _Libraries()..failUpdateFor = 'remote';
    final container = ProviderContainer(
      overrides: [
        libraryMigrationStoreProvider.overrideWithValue(
          const LibraryMigrationStoreImpl(),
        ),
        libraryRepoProvider.overrideWithValue(libraries),
        appSettingRepositoryProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    await container.read(librariesProvider.future);
    expect(libraries.saved.keys, ['local']);
    expect(
      (await settings.peekLegacyResourceFormatPayload())?.enabledFormatGroups,
      ['pdf'],
    );
    expect(
      prefs.getBool('migrated_enabled_format_groups_to_libraries_v1'),
      isNot(true),
    );
    libraries.failUpdateFor = null;
    await container.read(librariesProvider.notifier).refresh();
    expect(libraries.saved.values, everyElement([ResourceFormatCategory.pdf]));
    expect(
      prefs.getBool('migrated_enabled_format_groups_to_libraries_v1'),
      isTrue,
    );
    expect(await settings.peekLegacyResourceFormatPayload(), isNull);
  });

  test('no legacy payload keeps default formats', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppSettingRepositoryImpl settings = AppSettingRepositoryImpl(
      sharedPreferences: await SharedPreferences.getInstance(),
      legacySettingsFile: _LegacyFile(null),
    );
    expect(await settings.peekLegacyResourceFormatPayload(), isNull);
    final _Libraries libraries = _Libraries();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        libraryMigrationStoreProvider.overrideWithValue(
          const LibraryMigrationStoreImpl(),
        ),
        libraryRepoProvider.overrideWithValue(libraries),
        appSettingRepositoryProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    await container.read(librariesProvider.future);
    expect(libraries.saved.values, everyElement(ResourceFormatCategory.all));
  });

  group('Supported resource formats defaults', () {
    test('missing storage key migrates to all format groups enabled', () {
      expect(
        resourceFormatCategoriesFromStorage(null),
        ResourceFormatCategory.all,
      );
    });

    test('explicit empty list is preserved as all disabled', () {
      expect(resourceFormatCategoriesFromStorage(<String>[]), isEmpty);
    });

    test('requires confirm only when saving with no groups enabled', () {
      expect(
        requiresDisableAllResourceFormatCategoriesConfirm(
          ResourceFormatCategory.all,
        ),
        isFalse,
      );
      expect(
        requiresDisableAllResourceFormatCategoriesConfirm(
          <ResourceFormatCategory>[],
        ),
        isTrue,
      );
    });
  });
}
