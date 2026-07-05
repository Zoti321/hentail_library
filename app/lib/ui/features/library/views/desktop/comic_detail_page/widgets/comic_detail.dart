import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/detail_primary_row_layout.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_cover.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_header.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_info_sections.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_primary_actions.dart';

class ComicDetail extends StatelessWidget {
  const ComicDetail({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double horizontalPadding = detailContentHorizontalPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ComicDetailHeader(comic: comic),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              tokens.spacing.xl,
              horizontalPadding,
              tokens.spacing.xl + 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spacing.xl + 8,
              children: <Widget>[
                _buildPrimarySection(context, tokens, cs),
                ComicDetailMetadataBlock(comic: comic),
              ],
            )
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
                .slideY(
                  begin: 0.03,
                  duration: 260.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimarySection(
    BuildContext context,
    AppThemeTokens tokens,
    ColorScheme cs,
  ) {
    return DetailPrimaryRowLayout(
      cover: ComicDetailCover(comic: comic),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.md,
        children: <Widget>[
          Tooltip(
            message: comic.title,
            waitDuration: const Duration(milliseconds: 2000),
            child: SelectableText(
              comic.title,
              maxLines: 2,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: cs.hentai.textPrimary,
                height: 1.25,
              ),
            ),
          ),
          ComicDetailSummaryMetaRow(comic: comic),
          ComicDetailPrimaryActions(comic: comic),
        ],
      ),
    );
  }
}
