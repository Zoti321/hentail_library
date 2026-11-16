import 'package:riverpod/riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';

void main() {
  group('LibraryRevisionNotifier', () {
    test('starts at revision 0 before any event', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[...domainEventBusOverrides()],
      );
      addTearDown(container.dispose);

      expect(container.read(libraryRevisionProvider).revision, 0);
      expect(
        container.read(libraryRevisionProvider).hasReceivedFirstEmit,
        isFalse,
      );
    });

    test('bumps revision on catalog domain event', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[...domainEventBusOverrides()],
      );
      addTearDown(container.dispose);
      container.read(libraryRevisionProvider);

      container
          .read(domainEventBusProvider)
          .publish(const LibraryCatalogChanged(CatalogChangeSource.sync));

      final LibraryRevisionState state = container.read(
        libraryRevisionProvider,
      );
      expect(state.revision, 1);
      expect(state.hasReceivedFirstEmit, isTrue);
      expect(state.streamError, isNull);
    });
  });
}
