import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

/// [LibraryRevisionPort] 经 Rust FRB 轮询 SQLite data_version。
class LibraryRevisionFrbAdapter implements LibraryRevisionPort {
  const LibraryRevisionFrbAdapter();

  @override
  Stream<void> watchRevision() => guardFrbStream(
    () => rust.watchComicChanges().map((int _) {}),
    fallbackMessage: '监听库变更失败',
  );
}
