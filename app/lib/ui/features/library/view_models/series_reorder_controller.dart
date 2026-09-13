import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_reorder_controller.g.dart';

/// 系列详情预拉 / Series reorder mode 落库时单页拉取上限。
const int _kReorderFetchPageSize = 500;

/// 系列详情全量成员列表（打开详情即预拉；#121）。
///
/// - 供浏览态与 Series reorder mode 共用同一数据源（进入模式不换树）；
/// - **不**监听裸 [libraryRevisionProvider]（缩略图写入也会 bump）；由详情页在
///   sync / metadata refresh 完成或用户退出模式时 [invalidate] 重拉；
/// - [beginDrag] / [endDrag]：拖拽与落库窗口内冻结，避免 children 被换掉；
/// - [reorder] 乐观更新并落库；自身 bump 不触发本 notifier 重拉。
@riverpod
class SeriesReorderController extends _$SeriesReorderController {
  late String _seriesId;
  bool _dragActive = false;
  List<SeriesComicPageItem>? _dragSnapshot;

  void beginDrag() {
    _dragActive = true;
    final List<SeriesComicPageItem>? current = state.asData?.value;
    _dragSnapshot = current == null
        ? null
        : List<SeriesComicPageItem>.from(current);
  }

  void endDrag() {
    _dragActive = false;
    _dragSnapshot = null;
  }

  @override
  Future<List<SeriesComicPageItem>> build(String seriesId) async {
    _seriesId = seriesId;
    if (_dragActive && _dragSnapshot != null) {
      // 保活：拖中若被 invalidate，仍返回快照（正常路径不 watch revision）。
      return _dragSnapshot!;
    }
    return _loadAllMembers(seriesId);
  }

  Future<List<SeriesComicPageItem>> _loadAllMembers(String seriesId) async {
    final List<SeriesComicPageItem> all = <SeriesComicPageItem>[];
    int page = 1;
    while (true) {
      final PagedResult<SeriesComicPageItem> result = await ref
          .read(seriesRepoProvider)
          .fetchComicsPage(
            seriesId: seriesId,
            request: pageRequest(page: page, pageSize: _kReorderFetchPageSize),
          );
      all.addAll(result.items);
      if (result.items.isEmpty || page >= result.totalPages) {
        break;
      }
      page += 1;
    }
    return all;
  }

  /// 落库一次拖拽结果：乐观更新可视顺序，失败回滚并抛错。
  Future<void> reorder(List<SeriesComicPageItem> reordered) async {
    final List<SeriesComicPageItem>? previous = state.asData?.value;
    if (previous == null) {
      return;
    }
    final List<SeriesComicPageItem> snapshot = List<SeriesComicPageItem>.from(
      previous,
    );
    final List<SeriesComicPageItem> next = List<SeriesComicPageItem>.from(
      reordered,
    );
    state = AsyncData<List<SeriesComicPageItem>>(next);
    // 落库完成前保持冻结，避免 onDragEnd 已结束但 revision/重拉插入窗口。
    _dragActive = true;
    _dragSnapshot = next;
    try {
      await ref
          .read(seriesRepoProvider)
          .setSeriesItemsOrder(
            _seriesId,
            reordered
                .map(
                  (SeriesComicPageItem item) => SeriesItem(
                    comicId: item.comic.comicId,
                    order: item.sortOrder,
                    sortOrderLocked: item.sortOrderLocked,
                  ),
                )
                .toList(),
          );
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    } catch (error, stackTrace) {
      logError(AppLog.ui('series'), '系列成员重排落库失败', error, stackTrace);
      state = AsyncData<List<SeriesComicPageItem>>(snapshot);
      rethrow;
    } finally {
      endDrag();
    }
  }
}
