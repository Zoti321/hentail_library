import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_md3e/comic_detail_page_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/comic_detail/comic_detail_scroll_content.dart';
/// 详情滚动正文（独立 [SingleChildScrollView] 场景）。
class Md3eComicDetailBody extends StatelessWidget {
  const Md3eComicDetailBody({
    super.key,
    required this.entry,
    this.onRead,
    this.onReadIncognito,
    this.onMetadataChipTap,
  });

  final Md3eComicDetailEntry entry;
  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;
  final ValueChanged<String>? onMetadataChipTap;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double horizontalPadding =
        Md3eComicDetailPageMetrics.contentHorizontalPadding(sizeClass);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Md3eComicDetailScrollContent(
        entry: entry,
        onRead: onRead,
        onReadIncognito: onReadIncognito,
        onMetadataChipTap: onMetadataChipTap,
      ),
    );
  }
}
