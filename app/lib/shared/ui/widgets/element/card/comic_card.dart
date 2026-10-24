import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/element/card/catalog_cover_card_shell.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/context_menu/comic_context_menu.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

class ComicCard extends StatelessWidget {
  const ComicCard({
    super.key,
    required this.comic,
    required this.onTap,
    required this.onEditMetadata,
    required this.onReadComic,
    required this.onTrashComic,
    this.gridIndex,
    this.catalogCoverViewport,
    this.selectionMode = false,
  });

  final Comic comic;
  final VoidCallback onTap;
  final VoidCallback onEditMetadata;
  final VoidCallback onReadComic;
  final VoidCallback onTrashComic;
  final int? gridIndex;
  final ProviderListenable<Set<int>>? catalogCoverViewport;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return CatalogCoverCardShell(
      semanticLabel: comic.title,
      onTap: onTap,
      onSecondaryTapUp: selectionMode
          ? (_) => onTap()
          : (TapUpDetails details) {
              _showContextMenu(context, details.globalPosition);
            },
      onLongPressStart: selectionMode
          ? (_) => onTap()
          : (LongPressStartDetails details) {
              _showContextMenu(context, details.globalPosition);
            },
      cover: ComicCoverContent(
        comicId: comic.comicId,
        gridIndex: gridIndex,
        coverViewport: catalogCoverViewport,
      ),
      info: (bool isHover) => _ComicCardInfo(
        title: comic.title,
        pageCount: comic.pageCount,
        isHover: isHover,
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    ComicContextMenu.show(
      context,
      position: globalPosition,
      mangaTitle: comic.title,
      onAction: (ComicContextAction action) {
        final l10n = context.l10n;
        switch (action) {
          case ComicContextAction.read:
            onReadComic();
          case ComicContextAction.edit:
            onEditMetadata();
          case ComicContextAction.showInExplorer:
            showInFileExplorer(comic.path)
                .catchError((Object error, StackTrace stackTrace) {
                  debugPrint(
                    'showInFileExplorer failed for "${comic.path}": $error',
                  );
                  if (!context.mounted) {
                    return;
                  }
                  if (error is AppException) {
                    showErrorToast(context, error);
                    return;
                  }
                  showErrorToast(
                    context,
                    AppException(
                      l10n.comicDetailShowInExplorerFailed,
                      cause: error,
                      stackTrace: stackTrace,
                    ),
                  );
                });
          case ComicContextAction.delete:
            onTrashComic();
        }
      },
    );
  }
}

class _ComicCardInfo extends StatelessWidget {
  const _ComicCardInfo({
    required this.title,
    required this.pageCount,
    required this.isHover,
  });

  final String title;
  final int pageCount;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: tokens.text.bodyMd,
            fontWeight: FontWeight.w600,
            fontFamily: 'MI_Sans_Regular',
            height: 1.25,
            color: isHover ? cs.primary : context.hentai.textPrimary,
          ),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text(
          l10n.comicDetailPageCount(pageCount),
          style: TextStyle(
            fontSize: tokens.text.labelXs - 1,
            color: context.hentai.textTertiary,
          ),
        ),
      ],
    );
  }
}
