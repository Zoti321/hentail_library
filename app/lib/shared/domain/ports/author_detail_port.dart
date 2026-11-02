import 'package:flutter/widgets.dart';

/// 按作者名打开作者详情的跨模块契约（#292）。
///
/// 跨 feature 请 `import shared/di/author_detail_providers.dart` 并 `ref.read(authorDetailPortProvider)`。
/// 实现位于 library_browse；[authorDetailPortProvider] 在 shared/di 声明。
abstract interface class AuthorDetailPort {
  Future<void> showByName(BuildContext context, String name);
}
