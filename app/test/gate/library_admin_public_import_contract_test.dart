import 'package:test/test.dart';

import 'import_boundary_rules.dart';

void main() {
  test('M1 allows cross-feature import of library_admin public barrel only', () {
    const String allowedUri =
        'package:hentai_library/features/library_admin/public.dart';
    const String allowedDeep =
        'package:hentai_library/features/library_admin/public/library_admin_commands.dart';
    const String deniedUri =
        'package:hentai_library/features/library_admin/di/library_commands.dart';

    expect(isFeaturePublicPath('features/library_admin/public.dart'), isTrue);
    expect(
      isFeaturePublicPath(
        'features/library_admin/public/library_admin_commands.dart',
      ),
      isTrue,
    );
    expect(
      isFeaturePublicPath('features/library_admin/di/library_commands.dart'),
      isFalse,
    );

    expect(allowedUri.contains('/public'), isTrue);
    expect(allowedDeep.contains('/public/'), isTrue);
    expect(deniedUri.contains('/public'), isFalse);
  });
}
