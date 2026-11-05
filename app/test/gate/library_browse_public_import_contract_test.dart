import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of library_browse public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/library_browse/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
    const String deniedUri =
        'package:hentai_library/features/comic/domain/comic_lookup_repository.dart';

    expect(isFeaturePublicPath('features/library_browse/public.dart'), isTrue);
    expect(
      isFeaturePublicPath(
        'features/comic/public/ui/comic_cover_content.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath(
        'features/comic/domain/comic_lookup_repository.dart',
      ),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
