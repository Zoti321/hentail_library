import 'package:hentai_library/features/series/presentation/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_comics_catalog_state.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_jump.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_detail_page_facade_notifier.g.dart';

/// 系列详情页 Facade 投影：catalog + 每页数量。
typedef SeriesDetailPageFacadeState = ({
  AsyncValue<SeriesDetailComicsCatalogState> catalog,
  int pageSize,
  int? page,
});

/// 系列详情页根 Facade：叶子只经此订阅/发命令，不直订 catalog Controller。
@riverpod
class SeriesDetailPageFacadeNotifier extends _$SeriesDetailPageFacadeNotifier {
  @override
  SeriesDetailPageFacadeState build(String seriesId) {
    final AsyncValue<SeriesDetailComicsCatalogState> catalog = ref.watch(
      seriesDetailComicsCatalogControllerProvider(seriesId),
    );
    return (
      catalog: catalog,
      pageSize: ref.watch(seriesDetailActivePageSizeProvider),
      page: catalog.value?.pagination.page,
    );
  }

  void setPage(int page) {
    ref
        .read(seriesDetailComicsCatalogControllerProvider(seriesId).notifier)
        .setPage(page);
  }

  void jumpPage(PageJump jump) {
    ref
        .read(seriesDetailComicsCatalogControllerProvider(seriesId).notifier)
        .jump(jump);
  }

  void refresh() {
    ref
        .read(seriesDetailComicsCatalogControllerProvider(seriesId).notifier)
        .refresh();
  }
}
