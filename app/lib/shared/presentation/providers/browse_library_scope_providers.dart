import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'browse_library_scope_providers.g.dart';

/// 单库浏览路由 `/libraries/:id` 注入的 catalog 作用域；非库页为 null。
///
/// 使用 [claim]/[release] 绑定路由页生命周期：换库时旧页 dispose 的
/// release 不得清掉新页已 claim 的 id（否则 catalog 以 null 查询，Rust 返回空页）。
@Riverpod(keepAlive: true)
class BrowseLibraryId extends _$BrowseLibraryId {
  int _epoch = 0;

  @override
  String? build() => null;

  /// 声明当前浏览库；返回供 [release] 使用的 epoch。
  int claim(String? libraryId) {
    final String? normalized = _normalize(libraryId);
    _epoch += 1;
    state = normalized;
    return _epoch;
  }

  /// 仅当 [epoch] 仍是最新 claim 时清空作用域。
  void release(int epoch) {
    if (epoch != _epoch) {
      return;
    }
    state = null;
  }

  /// 测试与非路由写入；会推进 epoch，使此前 claim 的 release 失效。
  void setId(String? libraryId) {
    final String? normalized = _normalize(libraryId);
    if (state == normalized) {
      return;
    }
    _epoch += 1;
    state = normalized;
  }

  static String? _normalize(String? libraryId) {
    if (libraryId == null || libraryId.trim().isEmpty) {
      return null;
    }
    return libraryId.trim();
  }
}
