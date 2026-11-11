import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';

void main() {
  test('sharedLibraryStateOverrides 注入 library_admin currentLibraryPort', () {
    final ProviderContainer container = ProviderContainer(
      overrides: sharedLibraryStateOverrides(),
    );
    addTearDown(container.dispose);

    expect(() => container.read(librariesPortProvider), returnsNormally);
  });
}
