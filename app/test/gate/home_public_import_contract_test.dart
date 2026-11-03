import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of home public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/home/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/home/public/home_cross_feature_types.dart';
    const String deniedUri =
        'package:hentai_library/features/home/domain/home_page_repository.dart';

    expect(isFeaturePublicPath('features/home/public.dart'), isTrue);
    expect(
      isFeaturePublicPath('features/home/public/home_cross_feature_types.dart'),
      isTrue,
    );
    expect(
      isFeaturePublicPath('features/home/domain/home_page_repository.dart'),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
