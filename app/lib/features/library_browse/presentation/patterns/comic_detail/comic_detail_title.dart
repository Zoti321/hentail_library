import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 详情主标题（最多两行，可选 tooltip）。
class Md3eComicDetailTitle extends StatelessWidget {
  const Md3eComicDetailTitle({
    super.key,
    required this.title,
    this.maxLines = 2,
  });

  final String title;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
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
        style: Md3eComicDetailPageMetrics.titleTextStyle(
          sizeClass: sizeClass,
          typeScale: theme.typeScale,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
