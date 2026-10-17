import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/shared/domain/library/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:riverpod/misc.dart' show Override, ProviderException;
import 'package:hentai_library/features/library_browse/di/catalog_selection_command_port.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';

class _SilentRevisionPort implements LibraryRevisionPort {
  @override
  Stream<void> watchRevision() => const Stream<void>.empty();
}

void main() {
  test('未注入时 shared 端口与状态 Provider 抛出 UnimplementedError', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(libraryReorderModePortProvider),
      throwsA(isA<ProviderException>()),
    );
    expect(
      () => container.read(libraryRevisionStateProvider),
      throwsA(isA<ProviderException>()),
    );
  });

  test('libraryReorderModePortProvider delegates enter/exit to notifier', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryReorderModePortProvider.overrideWith(
          createLibraryReorderModePort,
        ),
        catalogSelectionCommandPortProvider.overrideWith(
          createCatalogSelectionCommandPort,
        ),
      ],
    );
    addTearDown(container.dispose);

    final LibraryReorderModePort port = container.read(
      libraryReorderModePortProvider,
    );
    expect(port.isActive, isFalse);

    port.enter();
    expect(port.isActive, isTrue);
    expect(container.read(libraryReorderModeProvider), isTrue);

    port.exit();
    expect(port.isActive, isFalse);
  });

  test('libraryRevisionSignalPortProvider bumps libraryRevisionProvider', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRevisionPortProvider.overrideWithValue(_SilentRevisionPort()),
        libraryRevisionSignalPortProvider.overrideWith(
          createLibraryRevisionSignalPort,
        ),
      ],
    );
    addTearDown(container.dispose);

    final int before = container.read(libraryRevisionProvider).revision;
    container.read(libraryRevisionSignalPortProvider).notifyExternalChange();
    expect(container.read(libraryRevisionProvider).revision, before + 1);
  });

  test('bootstrap 注入后 shared 状态 Provider 跟随 library_admin 变化', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        libraryRevisionPortProvider.overrideWithValue(_SilentRevisionPort()),
        ...sharedLibraryStateOverrides(),
      ],
    );
    addTearDown(container.dispose);

    final int before = container.read(libraryRevisionStateProvider).revision;
    container.read(libraryRevisionSignalPortProvider).notifyExternalChange();
    expect(container.read(libraryRevisionStateProvider).revision, before + 1);
  });
}
