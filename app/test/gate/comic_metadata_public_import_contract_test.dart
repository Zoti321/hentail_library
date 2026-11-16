import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of comic_metadata public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/comic_metadata/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/comic_metadata/public/comic_metadata_cross_feature_types.dart';
    const String allowedForm =
        'package:hentai_library/features/comic_metadata/public/comic_metadata_form.dart';
    const String deniedUri =
        'package:hentai_library/features/comic_metadata/domain/author_repository.dart';

    expect(isFeaturePublicPath('features/comic_metadata/public.dart'), isTrue);
    expect(
      isFeaturePublicPath(
        'features/comic_metadata/public/comic_metadata_cross_feature_types.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath(
        'features/comic_metadata/public/comic_metadata_form.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath(
        'features/comic_metadata/domain/author_repository.dart',
      ),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(allowedForm.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
