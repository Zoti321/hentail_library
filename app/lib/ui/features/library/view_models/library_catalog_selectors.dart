import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';

/// 重载期间保留上一次 catalog 中的展示计数（分页栏等 UI 使用）。
int stableCatalogDisplayedCount<T>(
  AsyncValue<T> catalogAsync, {
  required int Function(T state) readCount,
}) {
  return catalogAsync.when(
    data: readCount,
    loading: () =>
        catalogAsync.value == null ? 0 : readCount(catalogAsync.value as T),
    error: (Object _, StackTrace _) =>
        catalogAsync.value == null ? 0 : readCount(catalogAsync.value as T),
    skipLoadingOnReload: true,
  );
}

/// 细粒度 UI 选择器：工具条/布局切换等局部组件直接订阅。
final libraryDisplayTargetProvider = Provider<LibraryDisplayTarget>((Ref ref) {
  return ref.watch(
    libraryQueryIntentProvider.select(
      (LibraryQueryIntent state) => state.displayTarget,
    ),
  );
});

final libraryFilterQueryProvider = Provider<String>((Ref ref) {
  return ref.watch(
    libraryQueryIntentProvider.select(
      (LibraryQueryIntent state) => state.keyword,
    ),
  );
});

final libraryDisplayedComicCountProvider = Provider<int>((Ref ref) {
  final AsyncValue<LibraryComicsCatalogState> catalogAsync = ref.watch(
    libraryComicsCatalogControllerProvider,
  );
  return stableCatalogDisplayedCount(
    catalogAsync,
    readCount: (LibraryComicsCatalogState state) => state.displayedCount,
  );
});

final libraryDisplayedSeriesCountProvider = Provider<int>((Ref ref) {
  final AsyncValue<LibrarySeriesCatalogState> catalogAsync = ref.watch(
    librarySeriesCatalogControllerProvider,
  );
  return stableCatalogDisplayedCount(
    catalogAsync,
    readCount: (LibrarySeriesCatalogState state) => state.displayedCount,
  );
});

/// 漫画目录展示层：默认转发 controller，搜索页可 override。
final libraryComicsCatalogContentProvider =
    Provider<AsyncValue<LibraryComicsCatalogState>>((Ref ref) {
      return ref.watch(libraryComicsCatalogControllerProvider);
    });

/// 系列目录展示层：默认转发 controller，搜索页可 override。
final librarySeriesCatalogContentProvider =
    Provider<AsyncValue<LibrarySeriesCatalogState>>((Ref ref) {
      return ref.watch(librarySeriesCatalogControllerProvider);
    });
