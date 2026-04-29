import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/navigation/library_return_breadcrumb.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/responsive_layout/detail_page_layout.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_card.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_cover.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_metadata_section.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_primary_actions.dart';

class ComicDetail extends StatelessWidget {
  const ComicDetail({super.key, required this.comic});
  final Comic comic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;

    return DetailResponsiveLayout(
      header: LibraryReturnBreadcrumb(
        trailingLabel: comic.title,
        trailingTooltip: comic.title,
      ),
      headerSpacing: tokens.spacing.md + 4,
      bodyBuilder: (BuildContext context, DetailPanelSize panel) {
        return ComicDetailCard(
          maxWidth: panel.targetWidth,
          padding: EdgeInsets.all(tokens.spacing.xl),
          child: _buildCardContent(tokens, cs)
              .animate()
              .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
              .slideY(
                begin: 0.03,
                duration: 260.ms,
                curve: Curves.easeOutCubic,
              ),
        );
      },
    );
  }

  Widget _buildCardContent(AppThemeTokens tokens, ColorScheme cs) {
    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Tooltip(
          message: comic.title,
          waitDuration: const Duration(milliseconds: 2000),
          child: SelectableText(
            comic.title,
            maxLines: 1,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: cs.hentai.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Center(child: ComicDetailCover(comic: comic)),
        ),
        SizedBox(width: tokens.spacing.lg + 16),
        Flexible(
          flex: 3,
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: <Widget>[
                titleBlock,
                ComicDetailMetadataSection(comic: comic),
                ComicDetailPrimaryActions(comic: comic),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
