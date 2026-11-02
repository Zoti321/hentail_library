import 'package:hentai_library/shared/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/shared/data/adapters/remote_credentials_frb.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/read_session/domain/reader_session_port.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart' as rust;

/// [ReaderSessionPort] 委托 Rust 阅读会话 open/close/clear。
class ReaderSessionFrbAdapter implements ReaderSessionPort {
  const ReaderSessionFrbAdapter({required this._libraryRepository});

  final LibraryRepository _libraryRepository;

  @override
  Future<void> openComic(Comic comic) async {
    await pushRemoteLibraryCredentials(_libraryRepository);
    try {
      await rust.openReaderFrb(
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
