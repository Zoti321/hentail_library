import 'package:hentai_library/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart' as rust;

/// [ReaderSessionPort] 委托 Rust 阅读会话 open/close/clear。
class ReaderSessionFrbAdapter implements ReaderSessionPort {
  const ReaderSessionFrbAdapter();

  @override
  Future<void> openComic(Comic comic) async {
    try {
      rust.openReaderFrb(
        comicId: comic.comicId,
        path: comic.path,
        resourceType: mapResourceType(comic.resourceType),
      );
    } on HentaiErrorDto catch (error) {
      throwReaderException(
        error,
        resourceType: comic.resourceType,
        path: comic.path,
        comicId: comic.comicId,
      );
    }
  }

  @override
  Future<void> closeComic(String comicId) async {
    rust.closeReaderFrb(comicId: comicId);
  }

  @override
  Future<void> clear() async {
    rust.clearReaderSessionsFrb();
  }
}
