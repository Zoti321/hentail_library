import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  _FakeLibraryRevisionPort(this._events);

  final StreamController<void> _events;

  @override
  Stream<void> watchRevision() => _events.stream;
}

void main() {
  group('LibraryRevision', () {
    test('starts at revision 0 before first emit', () {
      final StreamController<void> events = StreamController<void>.broadcast();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionPortProvider.overrideWithValue(
            _FakeLibraryRevisionPort(events),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(libraryRevisionProvider).revision,
        0,
      );
      expect(
        container.read(libraryRevisionProvider).hasReceivedFirstEmit,
        isFalse,
      );
    });

    test('bumps revision and marks first emit on stream event', () async {
      final StreamController<void> events = StreamController<void>.broadcast();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionPortProvider.overrideWithValue(
            _FakeLibraryRevisionPort(events),
          ),
        ],
      );
      addTearDown(container.dispose);

      final Completer<LibraryRevisionState> completer =
          Completer<LibraryRevisionState>();
      container.listen(
        libraryRevisionProvider,
        (LibraryRevisionState? previous, LibraryRevisionState next) {
          if (next.revision == 1 && !completer.isCompleted) {
            completer.complete(next);
          }
        },
        fireImmediately: true,
      );

      events.add(null);

      final LibraryRevisionState state = await completer.future;
      expect(state.revision, 1);
      expect(state.hasReceivedFirstEmit, isTrue);
      expect(state.streamError, isNull);
    });

    test('records stream errors', () async {
      final StreamController<void> events = StreamController<void>.broadcast();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionPortProvider.overrideWithValue(
            _FakeLibraryRevisionPort(events),
          ),
        ],
      );
      addTearDown(container.dispose);

      final Completer<LibraryRevisionState> completer =
          Completer<LibraryRevisionState>();
      container.listen(
        libraryRevisionProvider,
        (LibraryRevisionState? previous, LibraryRevisionState next) {
          if (next.streamError != null && !completer.isCompleted) {
            completer.complete(next);
          }
        },
        fireImmediately: true,
      );

      final StateError error = StateError('stream failed');
      events.addError(error);

      final LibraryRevisionState state = await completer.future;
      expect(state.hasReceivedFirstEmit, isTrue);
      expect(state.streamError, same(error));
    });
  });
}
