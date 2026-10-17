import 'package:hentai_library/shared/domain/library/library_change.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_change_bus.g.dart';

/// 书库写入事件总线的状态：每类事件一个单调递增的 revision。
///
/// 订阅方 `select` 自己关心的 revision，变化即重取/调度，互不感知对方。
class LibraryChangeState {
  const LibraryChangeState({
    this.dictionaryRevision = 0,
    this.metadataSaveRevision = 0,
  });

  final int dictionaryRevision;
  final int metadataSaveRevision;
}

@Riverpod(keepAlive: true)
class LibraryChangeBus extends _$LibraryChangeBus {
  @override
  LibraryChangeState build() => const LibraryChangeState();

  void publish(LibraryChange change) {
    final bool dictionaries = change.dictionariesWritten;
    final bool metadataSaved = change.metadataSaved;
    if (!dictionaries && !metadataSaved) {
      return;
    }
    state = LibraryChangeState(
      dictionaryRevision: state.dictionaryRevision + (dictionaries ? 1 : 0),
      metadataSaveRevision:
          state.metadataSaveRevision + (metadataSaved ? 1 : 0),
    );
  }
}
