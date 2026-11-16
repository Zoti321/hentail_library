import 'package:hentai_library/design-system/design_system.dart';

/// 首页库列表顺序变换（纯函数；UI 只负责触发索引，持久化由上层处理）。
List<T> applyHomeLibraryListReorder<T>(
  List<T> items,
  int oldIndex,
  int newIndex,
) => applyReorder<T>(items, oldIndex, newIndex);
