import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_md3e/comic_detail_page_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/comic_detail/comic_detail_metadata_section.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/comic_detail/comic_detail_primary_block.dart';

/// 详情正文块（无滚动容器，供 [CustomScrollView] sliver 使用）。
class Md3eComicDetailScrollContent extends StatelessWidget {
  const Md3eComicDetailScrollContent({
    super.key,
    required this.entry,
    this.onRead,
    this.onReadIncognito,
    this.onMetadataChipTap,
    this.onAuthorTap,
  });

  final Md3eComicDetailEntry entry;
  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<String>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final double topSpacing = layout.headerToBodyGap;
    final double primaryToMetadata =
        Md3eComicDetailPageMetrics.primaryToMetadataSpacing(layout.sizeClass);

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
          onAuthorTap: onAuthorTap,
        ),
        SizedBox(height: Md3eComicDetailPageMetrics.scrollBottomInset),
      ],
    );
  }
}
