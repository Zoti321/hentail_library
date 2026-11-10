import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:riverpod/misc.dart' show Override, ProviderException;
import 'package:hentai_library/features/bootstrap/di/overrides/domain_event_bus_overrides.dart';

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

  test('LibraryCatalogChanged 事件 bumps libraryRevisionProvider', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[...domainEventBusOverrides()],
    );
    addTearDown(container.dispose);

    final int before = container.read(libraryRevisionProvider).revision;
    container
        .read(domainEventBusProvider)
        .publish(const LibraryCatalogChanged(CatalogChangeSource.sync));
    expect(container.read(libraryRevisionProvider).revision, before + 1);
  });

  test('bootstrap 注入后 shared 状态 Provider 跟随 library_admin 变化', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...domainEventBusOverrides(),
        ...sharedLibraryStateOverrides(),
        ...bootstrapCompositionOverrides(),
      ],
    );
    addTearDown(container.dispose);

    final int before = container.read(libraryRevisionStateProvider).revision;
    container
        .read(domainEventBusProvider)
        .publish(const LibraryCatalogChanged(CatalogChangeSource.sync));
    expect(container.read(libraryRevisionStateProvider).revision, before + 1);
  });
}
