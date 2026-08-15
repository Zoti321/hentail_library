import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/value_objects/form/library_settings_form.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:test/test.dart';

class _RecordingLibraryRepository implements LibraryRepository {
  String? libraryId;
  String? name;
  List<FormatGroup>? groups;
  bool? scanOnStartup;
  ScanInterval? scanInterval;
  int updateSettingsCallCount = 0;

  @override
  Future<LocalLibrary> updateSettings({
    required String libraryId,
    required String name,
    required List<FormatGroup> groups,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  }) async {
    updateSettingsCallCount += 1;
    this.libraryId = libraryId;
    this.name = name;
    this.groups = groups;
    this.scanOnStartup = scanOnStartup;
    this.scanInterval = scanInterval;
    return (
      libraryId: libraryId,
      kind: 'local',
      rootPath: '/root',
      name: name,
      enabledFormatGroups: groups,
      username: '',
      allowHttp: false,
      scanOnStartup: scanOnStartup,
      scanInterval: scanInterval,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LocalLibrary _library({
  String name = 'My Library',
  List<FormatGroup> groups = FormatGroup.all,
  bool scanOnStartup = false,
  ScanInterval scanInterval = ScanInterval.disabled,
  String kind = 'local',
}) {
  return (
    libraryId: 'lib-1',
    kind: kind,
    rootPath: kind == 'remote' ? 'https://dav.example/root' : r'D:\comics',
    name: name,
    enabledFormatGroups: groups,
    username: kind == 'remote' ? 'user' : '',
    allowHttp: false,
    scanOnStartup: scanOnStartup,
    scanInterval: scanInterval,
  );
}

void main() {
  group('LibrarySettingsForm.fromLibrary', () {
    test('maps editable settings fields', () {
      final LibrarySettingsForm form = LibrarySettingsForm.fromLibrary(
        _library(
          name: 'Alpha',
          groups: <FormatGroup>[FormatGroup.pdf, FormatGroup.epub],
          scanOnStartup: true,
          scanInterval: ScanInterval.hourly,
        ),
      );
      expect(form.name, 'Alpha');
      expect(form.enabledFormatGroups, <FormatGroup>[
        FormatGroup.pdf,
        FormatGroup.epub,
      ]);
      expect(form.scanOnStartup, isTrue);
      expect(form.scanInterval, ScanInterval.hourly);
    });
  });

  group('LibrarySettingsForm.validate / normalized', () {
    test('rejects blank name', () {
      final LibrarySettingsFormValidation v = LibrarySettingsForm(
        name: '  ',
        enabledFormatGroups: FormatGroup.all,
        scanOnStartup: false,
        scanInterval: ScanInterval.disabled,
      ).validate();
      expect(v.isValid, isFalse);
      expect(v.nameError, '库名称不能为空');
    });

    test('normalized trims name and orders format groups', () {
      final LibrarySettingsForm ready = LibrarySettingsForm(
        name: ' Alpha ',
        enabledFormatGroups: <FormatGroup>[
          FormatGroup.archive,
          FormatGroup.pdf,
        ],
        scanOnStartup: false,
        scanInterval: ScanInterval.disabled,
      ).normalized;
      expect(ready.name, 'Alpha');
      expect(ready.enabledFormatGroups, <FormatGroup>[
        FormatGroup.pdf,
        FormatGroup.archive,
      ]);
    });
  });

  group('LibrarySettingsForm.applyTo', () {
    test('does not call repository when nothing changed', () async {
      final LocalLibrary original = _library();
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibrarySettingsApplyResult result =
          await LibrarySettingsForm.fromLibrary(original).applyTo(
            repo,
            original,
          );
      expect(result, isA<LibrarySettingsApplySucceeded>());
      expect(repo.updateSettingsCallCount, 0);
    });

    test('returns invalid without calling repository', () async {
      final LocalLibrary original = _library();
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibrarySettingsApplyResult result = await LibrarySettingsForm(
        name: ' ',
        enabledFormatGroups: original.enabledFormatGroups,
        scanOnStartup: original.scanOnStartup,
        scanInterval: original.scanInterval,
      ).applyTo(repo, original);
      expect(result, isA<LibrarySettingsApplyInvalid>());
      expect(repo.updateSettingsCallCount, 0);
    });

    test('writes all settings when any field changed', () async {
      final LocalLibrary original = _library();
      final _RecordingLibraryRepository repo = _RecordingLibraryRepository();
      final LibrarySettingsApplyResult result = await LibrarySettingsForm(
        name: 'Renamed',
        enabledFormatGroups: <FormatGroup>[FormatGroup.pdf],
        scanOnStartup: true,
        scanInterval: ScanInterval.daily,
      ).applyTo(repo, original);

      expect(result, isA<LibrarySettingsApplySucceeded>());
      expect(repo.updateSettingsCallCount, 1);
      expect(repo.libraryId, 'lib-1');
      expect(repo.name, 'Renamed');
      expect(repo.groups, <FormatGroup>[FormatGroup.pdf]);
      expect(repo.scanOnStartup, isTrue);
      expect(repo.scanInterval, ScanInterval.daily);
    });
  });
}
