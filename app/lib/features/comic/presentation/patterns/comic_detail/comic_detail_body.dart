import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_scroll_content.dart';

/// 详情滚动正文（独立 [SingleChildScrollView] 场景）。
class ComicDetailBody extends StatelessWidget {
  const ComicDetailBody({
    super.key,
    required this.entry,
    this.onRead,
    this.onReadIncognito,
    this.onMetadataChipTap,
  });

  final ComicDetailViewObject entry;
  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;
  final ValueChanged<String>? onMetadataChipTap;

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = PageLayoutSpec.of(context)
        .horizontalInset;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ComicDetailScrollContent(
        entry: entry,
        onRead: onRead,
        onReadIncognito: onReadIncognito,
        onMetadataChipTap: onMetadataChipTap,
      ),
    );
  }
}
