import 'package:flutter/widgets.dart';

/// 按作者名打开作者详情的跨模块端口（#292）。
///
/// **迁移**：新代码请 import `features/library_browse/public.dart`（ADR-0034 / #434）。
/// 实现位于 library_browse；named_metadata 等模块只依赖本接口。
abstract interface class AuthorDetailPort {
  Future<void> showByName(BuildContext context, String name);
}
