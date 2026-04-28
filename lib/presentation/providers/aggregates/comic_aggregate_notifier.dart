import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_aggregate_notifier.g.dart';

class ComicAggregateState {
  const ComicAggregateState({
    this.rawList = const <Comic>[],
    this.hasReceivedFirstEmit = false,
    this.streamError,
  });
  final List<Comic> rawList;
  final bool hasReceivedFirstEmit;
  final Object? streamError;
  ComicAggregateState copyWith({
    List<Comic>? rawList,
    bool? hasReceivedFirstEmit,
    Object? streamError = _unsetStreamError,
  }) {
    return ComicAggregateState(
      rawList: rawList ?? this.rawList,
      hasReceivedFirstEmit: hasReceivedFirstEmit ?? this.hasReceivedFirstEmit,
      streamError: identical(streamError, _unsetStreamError)
          ? this.streamError
          : streamError,
    );
  }
}

const Object _unsetStreamError = Object();

@Riverpod(keepAlive: true)
class ComicAggregateNotifier extends _$ComicAggregateNotifier {
  StreamSubscription<List<Comic>>? _subscription;

  @override
  ComicAggregateState build() {
    _subscribeComicStream();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const ComicAggregateState();
  }

  void _subscribeComicStream() {
    final repo = ref.read(comicRepoProvider);
    _subscription = repo.watchAll().listen(
      (List<Comic> list) {
        state = state.copyWith(
          rawList: list,
          hasReceivedFirstEmit: true,
          streamError: null,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(hasReceivedFirstEmit: true, streamError: error);
      },
    );
  }

  void refreshStream() {
    _subscription?.cancel();
    _subscribeComicStream();
  }

  Comic? findComicById(String comicId) {
    return state.rawList.firstWhereOrNull(
      (Comic comic) => comic.comicId == comicId,
    );
  }
}
