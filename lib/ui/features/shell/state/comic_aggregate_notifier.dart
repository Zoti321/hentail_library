import 'dart:async';

import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_aggregate_notifier.g.dart';

class ComicAggregateState {
  const ComicAggregateState({
    this.changeGeneration = 0,
    this.hasReceivedFirstChange = false,
    this.streamError,
  });

  final int changeGeneration;
  final bool hasReceivedFirstChange;
  final Object? streamError;

  ComicAggregateState copyWith({
    int? changeGeneration,
    bool? hasReceivedFirstChange,
    Object? streamError = _unsetStreamError,
  }) {
    return ComicAggregateState(
      changeGeneration: changeGeneration ?? this.changeGeneration,
      hasReceivedFirstChange:
          hasReceivedFirstChange ?? this.hasReceivedFirstChange,
      streamError: identical(streamError, _unsetStreamError)
          ? this.streamError
          : streamError,
    );
  }
}

const Object _unsetStreamError = Object();

@Riverpod(keepAlive: true)
class ComicAggregateNotifier extends _$ComicAggregateNotifier {
  StreamSubscription<void>? _subscription;

  @override
  ComicAggregateState build() {
    _subscribeComicChanges();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const ComicAggregateState();
  }

  void _subscribeComicChanges() {
    final repo = ref.read(comicRepoProvider);
    _subscription = repo.watchChanges().listen(
      (_) {
        state = state.copyWith(
          changeGeneration: state.changeGeneration + 1,
          hasReceivedFirstChange: true,
          streamError: null,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(
          hasReceivedFirstChange: true,
          streamError: error,
        );
      },
    );
  }

  void refreshStream() {
    _subscription?.cancel();
    _subscribeComicChanges();
    state = state.copyWith(changeGeneration: state.changeGeneration + 1);
  }
}
