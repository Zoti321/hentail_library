import 'package:hentai_library/features/read_session/domain/reader_session_port.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_reader_session_port.dart';

/// 将 [ReaderSessionPort] 适配为 comic_trash 所需的 narrow seam。
final class ComicTrashReaderSessionAdapter
    implements ComicTrashReaderSessionPort {
  const ComicTrashReaderSessionAdapter(this._readerSessionPort);

  final ReaderSessionPort _readerSessionPort;

  @override
  Future<void> closeComic(String comicId) =>
      _readerSessionPort.closeComic(comicId);
}
