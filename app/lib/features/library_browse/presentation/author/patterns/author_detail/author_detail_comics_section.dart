import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_search_query_parser.dart';
import 'package:hentai_library/features/library_browse/public/ui/comic_cover_content.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/patterns/comic_detail/comic_detail_meta_chip_row.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

const double kMd3eAuthorDetailComicCardWidth = 96;
const double kMd3eAuthorDetailComicCardHeight = 144;

void openAuthorDetailSearch(BuildContext context, Iterable<String> names) {
  final String query = formatLibrarySearchAndExactMetaQuery(names);
  final String encoded = Uri.encodeQueryComponent(query);
  GoRouter.of(context).push('/searched?q=$encoded');
}

/// 作者作品区：元数据 chip + 封面网格，包在 tonal 卡片内。
class Md3eAuthorDetailComicsSection extends StatelessWidget {
  const Md3eAuthorDetailComicsSection({super.key, required this.detail});

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

    return Md3eContentSection(
      title: l10n.authorDetailComicsSection(detail.comicCount),
      titleTrailing: M3EButton(
        style: M3EButtonStyle.text,
        size: M3EButtonSize.sm,
        onPressed: () => openAuthorDetailSearch(context, <String>[detail.name]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Symbols.search, size: 16, color: scheme.primary),
            SizedBox(width: theme.spacing.xs),
            Text(l10n.authorDetailViewInSearch),
          ],
        ),
      ),
      padding: EdgeInsets.all(theme.spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (facets.isNotEmpty) ...<Widget>[
            Wrap(
              spacing: kMd3eComicDetailMetaChipGap,
              runSpacing: kMd3eComicDetailMetaChipGap,
              children: <Widget>[
                for (final AuthorFacetCount item in facets)
                  M3EChip(
                    label: '${item.name} ${item.attachmentCount}',
                    type: M3EChipType.suggestion,
                    onPressed: () => openAuthorDetailSearch(context, <String>[
                      item.name,
                      detail.name,
                    ]),
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
    final BorderRadius radius = BorderRadius.circular(12);
    return Tooltip(
      message: comic.title,
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        button: true,
        label: comic.title,
        child: SizedBox(
          width: kMd3eAuthorDetailComicCardWidth,
          height: kMd3eAuthorDetailComicCardHeight,
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  GoRouter.of(context)
                      .push('/comic/${Uri.encodeComponent(comic.comicId)}');
                },
                child: ComicCoverContent(comicId: comic.comicId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
