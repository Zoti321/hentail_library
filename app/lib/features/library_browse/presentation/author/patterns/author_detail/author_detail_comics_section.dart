import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';
import 'package:hentai_library/shared/ui/patterns/comic_detail/comic_detail_meta_chip_row.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/comic/public.dart';

const double kAuthorDetailComicCardWidth = 96;
const double kAuthorDetailComicCardHeight = 144;

/// 作者作品区：元数据 chip + 封面网格，包在 tonal 卡片内。
class AuthorDetailComicsSection extends StatelessWidget {
  const AuthorDetailComicsSection({super.key, required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final List<AuthorFacetCount> facets = <AuthorFacetCount>[
      ...detail.parodies,
      ...detail.characters,
      ...detail.tags,
    ];

    return ContentSection(
      title: l10n.authorDetailComicsSection(detail.comicCount),
      padding: EdgeInsets.all(theme.spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (facets.isNotEmpty) ...<Widget>[
            Wrap(
              spacing: kComicDetailMetaChipGap,
              runSpacing: kComicDetailMetaChipGap,
              children: <Widget>[
                for (final AuthorFacetCount item in facets)
                  M3EChip(
                    label: '${item.name} ${item.attachmentCount}',
                    type: M3EChipType.suggestion,
                  ),
              ],
            ),
            SizedBox(height: theme.spacing.lg),
          ],
          if (detail.topComics.isEmpty)
            Text(
              l10n.authorDetailComicsEmpty,
              style: type.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: theme.spacing.sm,
              runSpacing: theme.spacing.sm,
              children: <Widget>[
                for (final AuthorTopComic comic in detail.topComics)
                  _AuthorComicCoverCard(comic: comic),
              ],
            ),
        ],
      ),
    );
  }
}

class _AuthorComicCoverCard extends StatelessWidget {
  const _AuthorComicCoverCard({required this.comic});

  final AuthorTopComic comic;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = const BorderRadius.all(Radius.circular(12));
    return Tooltip(
      message: comic.title,
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        button: true,
        label: comic.title,
        child: SizedBox(
          width: kAuthorDetailComicCardWidth,
          height: kAuthorDetailComicCardHeight,
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => _handleTap(context),
                child: ComicCoverContent(comicId: comic.comicId),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    appNavigatorOf(context).pushComicDetail(comic.comicId);
  }
}
