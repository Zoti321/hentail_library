import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 详情主标题（漫画 / 系列共用，最多两行，可选 tooltip）。
///
/// 字阶与页面标题同源：来自 [PageLayoutSpec.titleStyle]（基于 `headlineSmall`）。
class ComicDetailTitle extends StatelessWidget {
  const ComicDetailTitle({
    super.key,
    required this.title,
    this.maxLines = 2,
  });

  final String title;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    return Tooltip(
      message: title,
      waitDuration: const Duration(milliseconds: 2000),
      child: SelectableText(
        title,
        maxLines: maxLines,
        // 多行 SelectableText 内部是 EditableText 的 Scrollable，会强制开启滚动条；
        // 标题不需要滚动，这里关闭其滚动条与过度滚动指示。
        scrollBehavior: ScrollConfiguration.of(context)
            .copyWith(scrollbars: false, overscroll: false),
        style: layout.titleStyle(theme.typeScale, theme.colorScheme.onSurface),
      ),
    );
  }
}
