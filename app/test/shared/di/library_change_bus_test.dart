import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';
import 'package:hentai_library/shared/domain/library/library_change.dart';
import 'package:test/test.dart';

void main() {
  group('libraryChangeBusProvider', () {
    test('dictionary write bumps only dictionary revision', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(libraryChangeBusProvider.notifier)
          .publish(const LibraryChange(tagsWritten: true));

      final LibraryChangeState state = container.read(libraryChangeBusProvider);
      expect(state.dictionaryRevision, 1);
      expect(state.metadataSaveRevision, 0);
    });

    test('metadata save bumps only save revision', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(libraryChangeBusProvider.notifier)
          .publish(const LibraryChange(metadataSaved: true));

      final LibraryChangeState state = container.read(libraryChangeBusProvider);
      expect(state.dictionaryRevision, 0);
      expect(state.metadataSaveRevision, 1);
    });

    test('empty change is ignored', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(libraryChangeBusProvider.notifier)
          .publish(const LibraryChange());

      final LibraryChangeState state = container.read(libraryChangeBusProvider);
      expect(state.dictionaryRevision, 0);
      expect(state.metadataSaveRevision, 0);
    });
  });
}
