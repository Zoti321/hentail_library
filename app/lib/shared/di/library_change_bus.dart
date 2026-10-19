import 'package:hentai_library/shared/domain/library/library_change.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_change_bus.g.dart';

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
