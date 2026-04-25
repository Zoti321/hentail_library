import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/navigation/library_return_breadcrumb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_constants.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_card.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_cover.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_metadata_section.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/comic_detail_primary_actions.dart';

class ComicDetail extends StatelessWidget {
  const ComicDetail({super.key, required this.comic});
  final Comic comic;
  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size mediaSize = MediaQuery.sizeOf(context);
        final double parentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaSize.width;
        final double parentHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaSize.height;
        final ComicDetailPanelSize panel = computeComicDetailPanelSize(
          parentWidth: parentWidth,
          parentHeight: parentHeight,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: panel.panelHeight),
            child: SizedBox(
            width: panel.panelWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LibraryReturnBreadcrumb(
                  trailingLabel: comic.title,
                  trailingTooltip: comic.title,
                ),
                SizedBox(height: tokens.spacing.md + 4),
                Expanded(
                  child: ComicDetailCard(
                    maxWidth: panel.targetWidth,
                    padding: EdgeInsets.all(tokens.spacing.xl),
                    child: _ComicDetailCardBody(comic: comic),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

class _ComicDetailCardBody extends ConsumerWidget {
  const _ComicDetailCardBody({required this.comic});
  final Comic comic;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
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
              color: cs.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
    final Widget cover = ComicDetailCover(comic: comic);
    final Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: <Widget>[
        titleBlock,
        ComicDetailMetadataSection(comic: comic),
        ComicDetailPrimaryActions(comic: comic),
      ],
    );
    final Widget layout = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Center(child: cover),
        ),
        SizedBox(width: tokens.spacing.lg + 16),
        Flexible(
          flex: 3,
          child: Align(
            alignment: Alignment.topLeft,
            child: rightColumn,
          ),
        ),
      ],
    );
    return layout
        .animate()
        .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.03, duration: 260.ms, curve: Curves.easeOutCubic);
  }
}
