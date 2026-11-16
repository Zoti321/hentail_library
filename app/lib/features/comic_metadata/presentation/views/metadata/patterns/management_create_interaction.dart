import 'package:flutter/widgets.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// 管理页「新建实体」交互：移动端 Dialog、桌面端 chip 流末尾内联字段。
enum ManagementCreateInteraction { mobileDialog, desktopInline }

/// 默认 compact 走 Dialog，medium 及以上走内联；[override] 供 Widgetbook Knob。
ManagementCreateInteraction managementCreateInteractionOf(
  BuildContext context, {
  ManagementCreateInteraction? override,
}) {
  if (override != null) {
    return override;
  }
  final WindowSizeClass sizeClass = windowSizeClassOf(context);
  return sizeClass.isCompact
      ? ManagementCreateInteraction.mobileDialog
      : ManagementCreateInteraction.desktopInline;
}
