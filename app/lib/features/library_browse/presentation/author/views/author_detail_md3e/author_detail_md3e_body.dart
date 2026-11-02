import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_search_query_parser.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail_md3e/author_detail_md3e_header.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_content.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _comicCardWidth = 96;
const double _comicCardHeight = 144;

/// 作者详情正文（MD3E sheet 内容）：头部 + 作品区。
class AuthorDetailMd3eBody extends ConsumerWidget {
  const AuthorDetailMd3eBody({super.key, required this.authorId});

  final int authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AuthorDetail?> asyncDetail = ref.watch(
      authorDetailProvider(authorId),
    );
    return asyncDetail.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) => Text('$error'),
      data: (AuthorDetail? detail) {
        if (detail == null) {
          return Text(l10n.comicDetailNotFound);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AuthorDetailMd3eHeader(detail: detail),
            const SizedBox(height: 24),
            _AuthorComicsSection(detail: detail),
          ],
        );
      },
    );
  }
}

void _openSearch(BuildContext context, Iterable<String> names) {
  final String query = formatLibrarySearchAndExactMetaQuery(names);
  final String encoded = Uri.encodeQueryComponent(query);
  GoRouter.of(context).push('/searched?q=$encoded');
}

class _AuthorComicsSection extends StatelessWidget {
  const _AuthorComicsSection({required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<AuthorFacetCount> facets = <AuthorFacetCount>[
      ...detail.parodies,
      ...detail.characters,
      ...detail.tags,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.authorDetailComicsSection(detail.comicCount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openSearch(context, <String>[detail.name]),
              icon: const Icon(LucideIcons.search, size: 14),
              label: Text(l10n.authorDetailViewInSearch),
            ),
          ],
        ),
        if (facets.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final AuthorFacetCount item in facets)
                OutlinedMetaChip(
                  text: '${item.name} ${item.attachmentCount}',
                  compact: true,
                  onTap: () =>
                      _openSearch(context, <String>[item.name, detail.name]),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (detail.topComics.isEmpty)
          Text(
            l10n.authorDetailComicsEmpty,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final AuthorTopComic comic in detail.topComics)
                _AuthorComicCoverCard(comic: comic),
            ],
          ),
      ],
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
          width: _comicCardWidth,
          height: _comicCardHeight,
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
