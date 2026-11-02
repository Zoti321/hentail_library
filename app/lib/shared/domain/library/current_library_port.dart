import 'package:hentai_library/shared/domain/library/library_sidebar_layout.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

/// 当前库选择与生命周期的命令端口（#260 步骤0；#261b 增加表单提交）。
///
/// 跨 feature 类型请 import `features/library_admin/public.dart`；
/// [currentLibraryPortProvider] 在 shared/di 声明，工厂见 owner public/di。
abstract class CurrentLibraryPort {
  /// 当前选中的 libraryId；未选中时为 null。
  Future<String?> currentId();

  Future<void> select(String libraryId);

  Future<void> clear();

  /// 删除 Library（不删盘，ADR-0012）。
  Future<void> deleteLibrary(String libraryId);

  /// 持久化侧栏 / 首页共用的库顺序与置顶布局（[LibrarySidebarPlacement]）。
  Future<void> updateSidebarLayout(List<LibrarySidebarPlacement> placements);

  /// 提交 Library 表单：[original] 为空时新建，否则编辑。成功后重载列表并通知 revision。
  Future<LibraryFormApplyResult> submitLibraryForm(
    LibraryForm form, {
    LocalLibrary? original,
  });
}
