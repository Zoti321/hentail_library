import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/catalog/selection/catalog_selection_notifier.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

class _NoopReorderModePort implements LibraryReorderModePort {
  @override
  bool get isActive => false;

  @override
  void enter() {}

  @override
  void exit() {}
}

void main() {
  test('entering reorder mode exits catalog multi-select', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        librariesStateProvider.overrideWithValue(
          const AsyncValue<LibrariesState>.data(
            LibrariesState(libraries: <LocalLibrary>[]),
          ),
        ),
        libraryReorderModePortProvider.overrideWithValue(
          _NoopReorderModePort(),
        ),
        libraryReorderActiveStateProvider.overrideWith(
          (Ref ref) => ref.watch(libraryReorderModeProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(catalogSelectionProvider.notifier).enter();
    expect(container.read(catalogSelectionProvider).active, isTrue);

    container.read(libraryReorderModeProvider.notifier).enter();

    expect(container.read(catalogSelectionProvider).active, isFalse);
    expect(container.read(libraryReorderModeProvider), isTrue);
  });
}
