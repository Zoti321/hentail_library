import 'package:hentai_library/shared/presentation/providers/library_reorder_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/ui/catalog/selection/catalog_selection_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

void main() {
  test('entering reorder mode exits catalog multi-select', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        librariesStateProvider.overrideWithValue(
          const AsyncValue<LibrariesState>.data(
            LibrariesState(libraries: <LocalLibrary>[]),
          ),
        ),
        exitLibraryReorderCommandProvider.overrideWithValue(() {}),
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
