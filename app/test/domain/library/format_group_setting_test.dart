import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting_migration.dart';

void main() {
  group('Supported resource formats defaults', () {
    test('missing storage key migrates to all format groups enabled', () {
      expect(
        legacyEnabledFormatGroupsFromJson(<String, dynamic>{}),
        FormatGroup.all,
      );
    });

    test('explicit empty list is preserved as all disabled', () {
      expect(formatGroupsFromStorage(<String>[]), isEmpty);
    });

    test('requires confirm only when saving with no groups enabled', () {
      expect(requiresDisableAllFormatGroupsConfirm(FormatGroup.all), isFalse);
      expect(requiresDisableAllFormatGroupsConfirm(<FormatGroup>[]), isTrue);
    });
  });
}
