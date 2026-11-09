import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';

/// 打开 Read session 的应用读模型：漫画、页列表与恢复页码（1-based）。
class OpenedReadSession {
  const OpenedReadSession({
    required this.comic,
    required this.pages,
    required this.resumePageIndex,
  });

  final Comic comic;
  final List<ReadSessionPage> pages;

  /// UI 使用的 1-based 页码。
  final int resumePageIndex;

  int get totalPages => pages.length;
}
