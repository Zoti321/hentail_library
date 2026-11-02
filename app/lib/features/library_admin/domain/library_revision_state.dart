/// Library revision 的共享只读状态（#261a 自 library_admin 迁入 shared/domain）。
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
