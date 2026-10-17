import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/shared/domain/library/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';

class _SilentRevisionPort implements LibraryRevisionPort {
  @override
  Stream<void> watchRevision() => const Stream<void>.empty();
}

void main() {
  test('libraryReorderModePortProvider delegates enter/exit to notifier', () {
    final ProviderContainer container = ProviderContainer();
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
      overrides: [
        libraryRevisionPortProvider.overrideWithValue(_SilentRevisionPort()),
      ],
    );
    addTearDown(container.dispose);

    final int before = container.read(libraryRevisionProvider).revision;
    container.read(libraryRevisionSignalPortProvider).notifyExternalChange();
    expect(container.read(libraryRevisionProvider).revision, before + 1);
  });
}
