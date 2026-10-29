import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/library/resource_format_category.dart';
import 'package:hentai_library/shared/domain/models/app_setting_migration.dart';

void main() {
  group('Supported resource formats defaults', () {
    test('missing storage key migrates to all format groups enabled', () {
      expect(
        legacyEnabledResourceFormatCategoriesFromJson(<String, dynamic>{}),
        ResourceFormatCategory.all,
      );
    });

    test('explicit empty list is preserved as all disabled', () {
      expect(resourceFormatCategoriesFromStorage(<String>[]), isEmpty);
    });

    test('requires confirm only when saving with no groups enabled', () {
      expect(requiresDisableAllResourceFormatCategoriesConfirm(ResourceFormatCategory.all), isFalse);
      expect(requiresDisableAllResourceFormatCategoriesConfirm(<ResourceFormatCategory>[]), isTrue);
    });
  });
}
