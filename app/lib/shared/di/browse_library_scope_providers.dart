import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browse_library_scope_providers.g.dart';

/// 单库浏览路由 `/libraries/:id` 注入的 catalog 作用域；非库页为 null。
@Riverpod(keepAlive: true)
class BrowseLibraryId extends _$BrowseLibraryId {
  @override
  String? build() => null;

  void setId(String? libraryId) {
    final String? normalized =
        libraryId == null || libraryId.trim().isEmpty ? null : libraryId.trim();
    if (state == normalized) {
      return;
    }
    state = normalized;
  }
}
