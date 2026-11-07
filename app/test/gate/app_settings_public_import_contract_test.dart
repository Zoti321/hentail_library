import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of app_settings public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/app_settings/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/app_settings/public/app_settings_cross_feature_types.dart';
    const String deniedUri =
        'package:hentai_library/features/app_settings/domain/app_setting.dart';

    expect(isFeaturePublicPath('features/app_settings/public.dart'), isTrue);
    expect(
      isFeaturePublicPath(
        'features/app_settings/public/app_settings_cross_feature_types.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath('features/app_settings/domain/app_setting.dart'),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
