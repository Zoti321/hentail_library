import 'package:flutter/widgets.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';

/// 管理页「新建实体」交互：移动端 Dialog、桌面端 chip 流末尾内联字段。
enum Md3eManagementCreateInteraction {
  mobileDialog,
  desktopInline,
}

/// 默认 compact 走 Dialog，medium 及以上走内联；[override] 供 Widgetbook Knob。
Md3eManagementCreateInteraction md3eManagementCreateInteractionOf(
  BuildContext context, {
  Md3eManagementCreateInteraction? override,
}) {
  if (override != null) {
    return override;
  }
  final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
  return sizeClass.isCompact
      ? Md3eManagementCreateInteraction.mobileDialog
      : Md3eManagementCreateInteraction.desktopInline;
}
