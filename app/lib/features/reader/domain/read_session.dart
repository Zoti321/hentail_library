import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/reader/domain/value_objects/read_session_page_index.dart';

/// 非无痕 Read session 实体：当前页与前台阅读时长（ADR-0005 / ADR-0038）。
///
/// 无痕路径不创建本实体。进度落盘与活动上报由 application Coordinator 编排。
final class ReadSession {
  ReadSession({
    required this.comic,
    required int initialPageIndex,
    required DateTime this._foregroundStartedAt,
  }) : _pageIndex = ReadSessionPageIndex.tryParse(
         _clampInitialPage(initialPageIndex, comic.pageCount),
         totalPages: comic.pageCount > 0 ? comic.pageCount : 0,
       );

  static int _clampInitialPage(int pageIndex, int pageCount) {
    if (pageCount > 0) {
      return pageIndex.clamp(1, pageCount);
    }
    return pageIndex < 1 ? 1 : pageIndex;
  }

  final Comic comic;
  ReadSessionPageIndex _pageIndex;
  DateTime? _foregroundStartedAt;
  Duration _accruedForeground = Duration.zero;

  String get comicId => comic.comicId;

  int get pageIndex => _pageIndex.value;

  /// 更新当前页（只强制 1-based；总页上界由打开/UI 侧 clamp）。
  void updatePage(int pageIndex) {
    _pageIndex = ReadSessionPageIndex.tryParse(pageIndex, totalPages: 0);
  }

  void pauseForeground(DateTime now) {
    final DateTime? started = _foregroundStartedAt;
    if (started == null) {
      return;
    }
    _accruedForeground += now.difference(started);
    _foregroundStartedAt = null;
  }

  void resumeForeground(DateTime now) {
    _foregroundStartedAt ??= now;
  }

  /// 取出并清零当前前台累计时长（含进行中的前台段）。
  Duration takeForegroundElapsed(DateTime now) {
    pauseForeground(now);
    final Duration elapsed = _accruedForeground;
    _accruedForeground = Duration.zero;
    return elapsed;
  }
}
