import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';

/// 打开阅读会话时的完整快照：漫画、页列表与恢复页码（1-based）。
class ReaderSessionSnapshot {
  const ReaderSessionSnapshot({
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
