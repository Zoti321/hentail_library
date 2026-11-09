import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of reader public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/reader/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/reader/public/reading_preference_types.dart';
    const String deniedUri =
        'package:hentai_library/features/reader/domain/native_reader_port.dart';

    expect(isFeaturePublicPath('features/reader/public.dart'), isTrue);
    expect(
      isFeaturePublicPath(
        'features/reader/public/reading_preference_types.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath('features/reader/domain/native_reader_port.dart'),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
