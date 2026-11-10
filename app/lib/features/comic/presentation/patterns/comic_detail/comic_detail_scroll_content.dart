import 'package:flutter/material.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_metadata_section.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_primary_block.dart';

/// 详情正文块（无滚动容器，供 [CustomScrollView] sliver 使用）。
class ComicDetailScrollContent extends StatelessWidget {
  const ComicDetailScrollContent({
    super.key,
    required this.entry,
    this.onRead,
    this.onReadIncognito,
    this.onMetadataChipTap,
    this.onAuthorTap,
  });

  final ComicDetailViewObject entry;
  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<AuthorRef>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double topSpacing = layout.headerToBodyGap;
    final double primaryToMetadata =
        ComicDetailPageMetrics.primaryToMetadataSpacing(layout.sizeClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: topSpacing),
        ComicDetailPrimaryBlock(
          entry: entry,
          onRead: onRead,
          onReadIncognito: onReadIncognito,
        ),
        SizedBox(height: primaryToMetadata),
        ComicDetailMetadataSection(
          entry: entry,
          onChipTap: onMetadataChipTap,
          onAuthorTap: onAuthorTap,
        ),
        SizedBox(height: ComicDetailPageMetrics.scrollBottomInset),
      ],
    );
  }
}
