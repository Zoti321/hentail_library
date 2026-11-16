import 'package:hentai_library/features/reader/public/native_reader_port.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_reader_session_port.dart';

/// 将 [NativeReaderPort] 适配为 comic_trash 所需的 narrow seam。
final class ComicTrashReaderSessionAdapter
    implements ComicTrashNativeReaderPort {
  const ComicTrashReaderSessionAdapter(this._readerSessionPort);

  final NativeReaderPort _readerSessionPort;

  @override
  Future<void> closeComic(String comicId) =>
      _readerSessionPort.closeComic(comicId);
}
