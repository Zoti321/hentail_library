import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_mode.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;

/// 无外部端口的 revision，避免 [LibraryRevision.build] 订阅 FRB port。
class _ControllableLibraryRevision extends LibraryRevision {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }
}

ProviderContainer _container() {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      libraryRevisionProvider.overrideWith(_ControllableLibraryRevision.new),
    ],
  );
  // 保活，避免 autoDispose 在两次读取之间复位。
  container.listen(seriesReorderModeProvider('s'), (_, _) {});
  return container;
}

void main() {
  test('defaults to off and enter turns it on', () {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);

    expect(container.read(seriesReorderModeProvider('s')), isFalse);

    container.read(seriesReorderModeProvider('s').notifier).enter();
    expect(container.read(seriesReorderModeProvider('s')), isTrue);
  });

  test('user exit turns it off and bumps library revision', () {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);

    container.read(seriesReorderModeProvider('s').notifier).enter();
    final int before = container.read(libraryRevisionProvider).revision;

    container.read(seriesReorderModeProvider('s').notifier).exit();

    expect(container.read(seriesReorderModeProvider('s')), isFalse);
    expect(container.read(libraryRevisionProvider).revision, before + 1);
  });

  test('external-change exit turns it off without bumping revision', () {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);

    container.read(seriesReorderModeProvider('s').notifier).enter();
    final int before = container.read(libraryRevisionProvider).revision;

    container
        .read(seriesReorderModeProvider('s').notifier)
        .exitForExternalChange();

    expect(container.read(seriesReorderModeProvider('s')), isFalse);
    expect(container.read(libraryRevisionProvider).revision, before);
  });

  test('modes for different series are independent', () {
    final ProviderContainer container = _container();
    container.listen(seriesReorderModeProvider('other'), (_, _) {});
    addTearDown(container.dispose);

    container.read(seriesReorderModeProvider('s').notifier).enter();

    expect(container.read(seriesReorderModeProvider('s')), isTrue);
    expect(container.read(seriesReorderModeProvider('other')), isFalse);
  });
}
