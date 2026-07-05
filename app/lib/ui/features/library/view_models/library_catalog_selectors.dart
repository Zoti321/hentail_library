import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';

/// 重载期间保留上一次 catalog 中的展示计数（分页栏等 UI 使用）。
int stableCatalogDisplayedCount(
  AsyncValue<LibraryPageSnapshot> catalogAsync, {
  required int Function(LibraryPageSnapshot snapshot) readCount,
}) {
  return catalogAsync.when(
    data: readCount,
    loading: () =>
        catalogAsync.value == null ? 0 : readCount(catalogAsync.value!),
    error: (Object _, StackTrace _) =>
        catalogAsync.value == null ? 0 : readCount(catalogAsync.value!),
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
  final AsyncValue<LibraryPageSnapshot> catalogAsync = ref.watch(
    libraryCatalogControllerProvider,
  );
  return stableCatalogDisplayedCount(
    catalogAsync,
    readCount: (LibraryPageSnapshot snapshot) => snapshot.displayedComicCount,
  );
});

final libraryDisplayedSeriesCountProvider = Provider<int>((Ref ref) {
  final AsyncValue<LibraryPageSnapshot> catalogAsync = ref.watch(
    libraryCatalogControllerProvider,
  );
  return stableCatalogDisplayedCount(
    catalogAsync,
    readCount: (LibraryPageSnapshot snapshot) => snapshot.displayedSeriesCount,
  );
});
