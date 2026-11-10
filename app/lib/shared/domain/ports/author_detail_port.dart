import 'package:flutter/widgets.dart';

/// 按作者名打开作者详情的跨模块契约（#292）。
///
/// 跨 feature 请 `import shared/di/author_detail_providers.dart` 并 `ref.read(authorDetailPortProvider)`。
/// 实现位于 library_browse；[authorDetailPortProvider] 在 shared/di 声明。
abstract interface class AuthorDetailPort {
  /// 按 Author 稳定 id 打开详情（有引用时首选，避免名字往返解析）。
  Future<void> showById(BuildContext context, int authorId);

  /// 按显示名打开详情（仅名字可用时的退化路径）。
  Future<void> showByName(BuildContext context, String name);
}
