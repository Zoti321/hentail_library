import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';

void main() {
  group('Supported resource formats defaults', () {
    test('AppSetting defaults enable all format groups', () {
      expect(AppSetting().enabledFormatGroups, FormatGroup.all);
    });

    test('missing storage key migrates to all format groups enabled', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{});
      expect(setting.enabledFormatGroups, FormatGroup.all);
    });

    test('explicit empty list is preserved as all disabled', () {
      expect(formatGroupsFromStorage(<String>[]), isEmpty);
    });

    test('requires confirm only when saving with no groups enabled', () {
      expect(requiresDisableAllFormatGroupsConfirm(FormatGroup.all), isFalse);
      expect(requiresDisableAllFormatGroupsConfirm(<FormatGroup>[]), isTrue);
    });
  });

  group('Supported resource formats draft persistence', () {
    test('toggling draft without save leaves repository unchanged', () async {
      final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository(
        AppSetting(),
      );
      final AppSetting committed = await repo.load();
      final Set<FormatGroup> draft = Set<FormatGroup>.from(
        committed.enabledFormatGroups,
      )..remove(FormatGroup.pdf);

      expect(draft.contains(FormatGroup.pdf), isFalse);
      expect(
        (await repo.load()).enabledFormatGroups,
        FormatGroup.all,
        reason: '离开子页未点保存时不应落盘',
      );
    });

    test('saving empty groups after confirm persists all disabled', () async {
      final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository(
        AppSetting(),
      );
      final List<FormatGroup> empty = <FormatGroup>[];
      expect(requiresDisableAllFormatGroupsConfirm(empty), isTrue);
      await repo.save(AppSetting(enabledFormatGroups: empty));
      expect((await repo.load()).enabledFormatGroups, isEmpty);
    });
  });
}

class _MemoryAppSettingRepository implements AppSettingRepository {
  _MemoryAppSettingRepository(this._setting);

  AppSetting _setting;

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    _setting = setting;
  }

  @override
  Future<bool?> peekLegacyAutoScan() async => null;
}
