import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('LibraryIncludeSetFilter', () {
    test('selectOnly replaces selection with a single value', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final LibraryIncludeSetFilter notifier = container.read(
        libraryIncludeSetFilterProvider(
          LibraryIncludeSetKind.parody,
        ).notifier,
      );

      await notifier.toggle('a');
      await notifier.toggle('b');
      await notifier.selectOnly('  Naruto  ');

      expect(
        container.read(
          libraryIncludeSetFilterProvider(LibraryIncludeSetKind.parody),
        ),
        <String>{'Naruto'},
      );
    });

    test('selectOnly with empty value clears selection', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final LibraryIncludeSetFilter notifier = container.read(
        libraryIncludeSetFilterProvider(
          LibraryIncludeSetKind.language,
        ).notifier,
      );

      await notifier.selectOnly('Chinese');
      await notifier.selectOnly('   ');

      expect(
        container.read(
          libraryIncludeSetFilterProvider(LibraryIncludeSetKind.language),
        ),
        isEmpty,
      );
    });
  });
}
