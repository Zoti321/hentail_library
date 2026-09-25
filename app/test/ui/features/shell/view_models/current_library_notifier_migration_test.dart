import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/view_models/current_library_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocalLibrary _library({required String id}) {
  return (
    libraryId: id,
    kind: 'local',
    rootPath: '/$id',
    name: id,
    enabledFormatGroups: const <FormatGroup>[],
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: true,
    sidebarOrder: 0,
  );
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository(this._libraries);

  final List<LocalLibrary> _libraries;
  bool allScanOnStartup = false;
  final Map<String, List<FormatGroup>> formatGroupsByLibrary =
      <String, List<FormatGroup>>{};

  @override
  Future<List<LocalLibrary>> list() async =>
      List<LocalLibrary>.from(_libraries);

  @override
  Future<String?> getCurrentId() async =>
      _libraries.isEmpty ? null : _libraries.first.libraryId;

  @override
  Future<void> setCurrentId(String? libraryId) async {}

  @override
  Future<void> setAllScanOnStartup(bool enabled) async {
    allScanOnStartup = enabled;
  }

  @override
  Future<LocalLibrary> updateFormatGroups({
    required String libraryId,
    required List<FormatGroup> groups,
  }) async {
    formatGroupsByLibrary[libraryId] = List<FormatGroup>.from(groups);
    for (final LocalLibrary library in _libraries) {
      if (library.libraryId == libraryId) {
        return (
          libraryId: library.libraryId,
          kind: library.kind,
          rootPath: library.rootPath,
          name: library.name,
          enabledFormatGroups: List<FormatGroup>.from(groups),
          username: library.username,
          allowHttp: library.allowHttp,
          scanOnStartup: library.scanOnStartup,
          scanInterval: library.scanInterval,
          pinned: library.pinned,
          sidebarOrder: library.sidebarOrder,
        );
      }
    }
    throw StateError('missing library $libraryId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppSettingRepository implements AppSettingRepository {
  _FakeAppSettingRepository({this.legacyAutoScan, this.legacyFormatGroups});

  final bool? legacyAutoScan;
  final List<FormatGroup>? legacyFormatGroups;
  int clearLegacyCalls = 0;

  @override
  Future<void> clearLegacyImportPayload() async {
    clearLegacyCalls++;
  }

  @override
  Future<AppSetting> load() async => AppSetting();

  @override
  Future<bool?> peekLegacyAutoScan() async => legacyAutoScan;

  @override
  Future<List<FormatGroup>?> peekLegacyEnabledFormatGroups() async =>
      legacyFormatGroups;

  @override
  Future<void> save(AppSetting setting) async {}
}

void main() {
  test(
    'migrates legacy format groups and autoScan to libraries once',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _FakeLibraryRepository libraryRepo = _FakeLibraryRepository(
        <LocalLibrary>[_library(id: 'lib-a'), _library(id: 'lib-b')],
      );
      final _FakeAppSettingRepository appSettingRepo =
          _FakeAppSettingRepository(
            legacyAutoScan: true,
            legacyFormatGroups: <FormatGroup>[FormatGroup.pdf],
          );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          libraryRepoProvider.overrideWithValue(libraryRepo),
          appSettingRepoProvider.overrideWithValue(appSettingRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentLibraryProvider.future);
      await container.read(currentLibraryProvider.future);

      expect(libraryRepo.allScanOnStartup, isTrue);
      expect(libraryRepo.formatGroupsByLibrary['lib-a'], <FormatGroup>[
        FormatGroup.pdf,
      ]);
      expect(libraryRepo.formatGroupsByLibrary['lib-b'], <FormatGroup>[
        FormatGroup.pdf,
      ]);
      expect(appSettingRepo.clearLegacyCalls, 1);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('migrated_enabled_format_groups_to_libraries_v1'),
        isTrue,
      );
      expect(prefs.getBool('migrated_auto_scan_to_libraries_v1'), isTrue);
    },
  );
}
