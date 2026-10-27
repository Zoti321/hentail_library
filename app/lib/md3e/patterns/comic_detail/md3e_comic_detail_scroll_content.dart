import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_metadata_section.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_primary_block.dart';
/// 详情正文块（无滚动容器，供 [CustomScrollView] sliver 使用）。
class Md3eComicDetailScrollContent extends StatelessWidget {
  const Md3eComicDetailScrollContent({
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
    final double topSpacing =
        Md3eComicDetailPageMetrics.catalogBodyTopSpacing(sizeClass);
    final double primaryToMetadata =
        Md3eComicDetailPageMetrics.primaryToMetadataSpacing(sizeClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: topSpacing),
        Md3eComicDetailPrimaryBlock(
          entry: entry,
          onRead: onRead,
          onReadIncognito: onReadIncognito,
        ),
        SizedBox(height: primaryToMetadata),
        Md3eComicDetailMetadataSection(
          entry: entry,
          onChipTap: onMetadataChipTap,
        ),
        SizedBox(height: Md3eComicDetailPageMetrics.scrollBottomInset),
      ],
    );
  }
}
