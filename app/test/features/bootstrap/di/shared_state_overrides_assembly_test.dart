import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test('sharedLibraryStateOverrides 注入 library_admin currentLibraryPort', () {
    final ProviderContainer container = ProviderContainer(
      overrides: sharedLibraryStateOverrides(),
    );
    addTearDown(container.dispose);

    expect(() => container.read(librariesPortProvider), returnsNormally);
  });
}
