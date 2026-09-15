import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/immersive_cover_header.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/detail_primary_row_layout.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_cover.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_header.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_info_sections.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_primary_actions.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicDetail extends ConsumerWidget {
  const ComicDetail({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double horizontalPadding = detailContentHorizontalPadding(context);
    final ComicCoverState coverState = ref.watch(
      comicCoverProvider(comic.comicId),
    );
    final ComicCoverImage? backdropCover = switch (coverState) {
      ComicCoverReady(:final data) => data,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ComicDetailHeader(comic: comic),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              0,
              tokens.spacing.xl,
              0,
              tokens.spacing.xl + 8,
            ),
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: tokens.spacing.xl + 8,
                      children: <Widget>[
                        ImmersiveCoverHeader(
                          backdropCover: backdropCover,
                          coverAspectRatio:
                              ComicDetailCover.containerAspectRatio,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          cover: ComicDetailCover(comic: comic),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: tokens.spacing.md,
                            children: <Widget>[
                              Tooltip(
                                message: comic.title,
                                waitDuration: const Duration(
                                  milliseconds: 2000,
                                ),
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
                              ComicDetailDescription(comic: comic),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: ComicDetailMetadataBlock(comic: comic),
                        ),
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
}
