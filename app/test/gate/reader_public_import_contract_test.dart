import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of read_session public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/read_session/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/read_session/public/reading_preference_types.dart';
    const String deniedUri =
        'package:hentai_library/features/read_session/domain/reader_session_port.dart';

    expect(isFeaturePublicPath('features/read_session/public.dart'), isTrue);
    expect(
      isFeaturePublicPath(
        'features/read_session/public/reading_preference_types.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath(
        'features/read_session/domain/reader_session_port.dart',
      ),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
