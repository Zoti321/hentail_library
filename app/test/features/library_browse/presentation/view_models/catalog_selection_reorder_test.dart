import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/shared/domain/library/library_reorder_mode_port.dart';
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
        currentLibraryStateProvider.overrideWithValue(
          const AsyncValue<CurrentLibraryState>.data(
            CurrentLibraryState(libraries: [], currentId: null),
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
