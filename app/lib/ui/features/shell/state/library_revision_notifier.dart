import 'dart:async';

import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_revision_notifier.g.dart';

class LibraryRevisionState {
  const LibraryRevisionState({
    this.revision = 0,
    this.hasReceivedFirstEmit = false,
    this.streamError,
  });

  final int revision;
  final bool hasReceivedFirstEmit;
  final Object? streamError;

  LibraryRevisionState copyWith({
    int? revision,
    bool? hasReceivedFirstEmit,
    Object? streamError = _unsetStreamError,
  }) {
    return LibraryRevisionState(
      revision: revision ?? this.revision,
      hasReceivedFirstEmit: hasReceivedFirstEmit ?? this.hasReceivedFirstEmit,
      streamError: identical(streamError, _unsetStreamError)
          ? this.streamError
          : streamError,
    );
  }
}

const Object _unsetStreamError = Object();

@Riverpod(keepAlive: true)
class LibraryRevision extends _$LibraryRevision {
  StreamSubscription<void>? _subscription;

  @override
  LibraryRevisionState build() {
    _subscribeRevision();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const LibraryRevisionState();
  }

  void _subscribeRevision() {
    final port = ref.read(libraryRevisionPortProvider);
    _subscription = port.watchRevision().listen(
      (_) => _bumpRevision(),
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(hasReceivedFirstEmit: true, streamError: error);
      },
    );
  }

  /// Sync 完成等 stream 可能已错过的外部变更通知。
  void notifyExternalChange() {
    _bumpRevision();
  }

  void _bumpRevision() {
    state = state.copyWith(
      revision: state.revision + 1,
      hasReceivedFirstEmit: true,
      streamError: null,
    );
  }
}
