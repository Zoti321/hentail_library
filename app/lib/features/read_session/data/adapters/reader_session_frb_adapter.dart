import 'package:hentai_library/features/read_session/data/mappers/reader_frb_mapper.dart';
import 'package:hentai_library/shared/domain/models/resource_type_frb_wire.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/read_session/domain/reader_session_port.dart';
import 'package:hentai_library/shared/domain/ports/remote_library_credentials_port.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart' as rust;

/// [ReaderSessionPort] 委托 Rust 阅读会话 open/close/clear。
class ReaderSessionFrbAdapter implements ReaderSessionPort {
  const ReaderSessionFrbAdapter({required this._remoteCredentials});

  final RemoteLibraryCredentialsPort _remoteCredentials;

  @override
  Future<void> openComic(Comic comic) async {
    await _remoteCredentials.pushStoredRemoteCredentialsToRust();
    try {
      await rust.openReaderFrb(
        comicId: comic.comicId,
        path: comic.path,
        resourceType: mapResourceType(comic.resourceType),
      );
    } on HentaiErrorDto catch (error) {
      throwReaderException(error, path: comic.path, comicId: comic.comicId);
    }
  }

  @override
  Future<void> closeComic(String comicId) async {
    await rust.closeReaderFrb(comicId: comicId);
  }

  @override
  Future<void> clear() async {
    rust.clearReaderSessionsFrb();
  }
}
