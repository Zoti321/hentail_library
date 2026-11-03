import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of comic_trash public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/comic_trash/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/comic_trash/public/comic_trash_cross_feature_types.dart';
    const String deniedUri =
        'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';

    expect(isFeaturePublicPath('features/comic_trash/public.dart'), isTrue);
    expect(
      isFeaturePublicPath(
        'features/comic_trash/public/comic_trash_cross_feature_types.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath('features/comic_trash/domain/trashed_comic.dart'),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
