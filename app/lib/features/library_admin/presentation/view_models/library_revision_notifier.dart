import 'dart:async';

import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/library/library_revision_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:hentai_library/shared/domain/library/library_revision_state.dart';

part 'library_revision_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryRevisionNotifier extends _$LibraryRevisionNotifier {
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
