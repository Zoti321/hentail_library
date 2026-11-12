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
  test('未注入时 shared 命令与状态 Provider 抛出 UnimplementedError', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(exitLibraryReorderCommandProvider),
      throwsA(isA<ProviderException>()),
    );
    expect(
      () => container.read(libraryRevisionStateProvider),
      throwsA(isA<ProviderException>()),
    );
  });

  test('command creation is inert; explicit exit updates reorder state', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        exitLibraryReorderCommandProvider.overrideWith(
          createExitLibraryReorderCommand,
        ),
      ],
    );
    addTearDown(container.dispose);

    final exit = container.read(exitLibraryReorderCommandProvider);
    expect(container.read(libraryReorderModeProvider), isFalse);
    container.read(libraryReorderModeProvider.notifier).enter();
    expect(container.read(libraryReorderModeProvider), isTrue);
    exit();
    expect(container.read(libraryReorderModeProvider), isFalse);
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
