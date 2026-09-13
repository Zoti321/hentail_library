import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_reorder_controller.g.dart';

/// Series reorder mode 落库时单页拉取上限（远超常见系列成员数，避免真正翻页）。
const int _kReorderFetchPageSize = 500;

/// Series reorder mode 的成员列表状态（#121）。
///
/// - 进入模式后关闭分页，一次性组合分页接口拉取「全部成员」，按 `sort_order` 有序；
/// - [reorder] 立即（乐观）更新可视顺序并落库；失败回滚到落库前快照并向上抛错供 UI 提示。
///
/// 成功落库不在此 bump revision：普通系列详情目录会在退出 Series reorder mode 时随
/// [SeriesReorderMode.exit] 的 revision 通知刷新（见 `series_reorder_mode.dart`）。
@riverpod
class SeriesReorderController extends _$SeriesReorderController {
  late String _seriesId;

  @override
  Future<List<SeriesComicPageItem>> build(String seriesId) async {
    _seriesId = seriesId;
    // 外部 Library sync / Metadata refresh 变更时重新加载全部成员。
    ref.watch(
      libraryRevisionProvider.select(
        (LibraryRevisionState state) => state.revision,
      ),
    );
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
    state = AsyncData<List<SeriesComicPageItem>>(
      List<SeriesComicPageItem>.from(reordered),
    );
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
    } catch (_) {
      // 落库失败：回滚可视顺序到拖拽前快照，向上抛错供页面弹 toast。
      state = AsyncData<List<SeriesComicPageItem>>(snapshot);
      rethrow;
    }
  }
}
