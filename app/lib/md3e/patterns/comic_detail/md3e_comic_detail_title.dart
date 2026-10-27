import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
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
        style: Md3eComicDetailPageMetrics.titleTextStyle(
          sizeClass: sizeClass,
          typeScale: theme.typeScale,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
