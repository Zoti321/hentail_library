import 'package:flutter/widgets.dart';
import 'package:hentai_library/design-system/components/menu/anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 弹出 M3E 选择菜单（锚定在触发行上），选中项回传给 [onSelected]。
Future<void> pickAnchoredOption<T extends Object>(
  BuildContext context, {
  required List<T> options,
  required T selected,
  required String Function(T option) labelOf,
  required ValueChanged<T> onSelected,
}) async {
  final Rect? anchor = menuAnchorRectFor(context);
  if (anchor == null) {
    return;
  }
  final Object? picked = await showAnchoredMenu<Object>(
    context: context,
    anchor: anchor,
    children: <M3EMenuNode>[
      for (final T option in options)
        M3EMenuSelectable(
          label: labelOf(option),
          value: option,
          selected: option == selected,
        ),
    ],
  );
  if (picked is T) {
    onSelected(picked);
  }
}
