import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';

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
    libraryQueryIntentProvider.select((LibraryQueryIntent state) => state.keyword),
  );
});

final libraryDisplayedComicCountProvider = Provider<int>((Ref ref) {
  final AsyncValue<LibraryPageSnapshot> catalogAsync = ref.watch(
    libraryCatalogControllerProvider,
  );
  return catalogAsync.when(
    data: (LibraryPageSnapshot snapshot) => snapshot.displayedComicCount,
    loading: () => catalogAsync.value?.displayedComicCount ?? 0,
    error: (Object _, StackTrace _) =>
        catalogAsync.value?.displayedComicCount ?? 0,
    skipLoadingOnReload: true,
  );
});

final libraryDisplayedSeriesCountProvider = Provider<int>((Ref ref) {
  final AsyncValue<LibraryPageSnapshot> catalogAsync = ref.watch(
    libraryCatalogControllerProvider,
  );
  return catalogAsync.when(
    data: (LibraryPageSnapshot snapshot) => snapshot.displayedSeriesCount,
    loading: () => catalogAsync.value?.displayedSeriesCount ?? 0,
    error: (Object _, StackTrace _) =>
        catalogAsync.value?.displayedSeriesCount ?? 0,
    skipLoadingOnReload: true,
  );
});
