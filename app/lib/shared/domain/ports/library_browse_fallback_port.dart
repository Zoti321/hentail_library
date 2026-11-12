import 'package:flutter/widgets.dart';

/// 「回到默认库浏览」降级命令（ADR-0045 shared 消费方豁免）。
///
/// 消费方是 `shared/ui`（返回栏 / 详情状态页 / 路由兜底页），它们只持
/// [BuildContext]，无法 import owner。全量库管理命令见
/// `features/library_admin/public.dart` 的 `LibraryManagementPort`。
///
/// 实现 @ `library_admin`；token `libraryBrowseFallbackPortProvider` 在
/// `shared/di` 声明，由 bootstrap 注入。
abstract interface class LibraryBrowseFallbackPort {
  /// 无具体库上下文时回 Home。
  void goDefaultLibraryBrowse(BuildContext context);
}
