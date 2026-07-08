import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/comic_context_menu.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_metadata_dialog.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicCard extends ConsumerWidget {
  const ComicCard({super.key, required this.comic, required this.onTap});

  final Comic comic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CatalogCoverCardShell(
      onTap: onTap,
      onSecondaryTapUp: (TapUpDetails details) {
        _showContextMenu(context, ref, details);
      },
      cover: ComicCoverContent(comicId: comic.comicId),
      info: (bool isHover) => _ComicCardInfo(
        title: comic.title,
        pageCount: comic.pageCount,
        isHover: isHover,
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    TapUpDetails details,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset relativePosition = overlay.globalToLocal(
      details.globalPosition,
    );

    ComicContextMenu.show(
      context,
      position: relativePosition,
      mangaTitle: comic.title,
      onAction: (ComicContextAction action) {
        switch (action) {
          case ComicContextAction.read:
            appRouter.pushNamed(
              ReaderRouteArgs.readerRouteName,
              queryParameters: ReaderRouteArgs(
                comicId: comic.comicId,
              ).toQueryParameters(),
            );
          case ComicContextAction.edit:
            showDialog<void>(
              context: context,
              builder: (BuildContext context) => EditMetadataDialog(
                comic: comic,
                onSave: (ComicMetadataForm data) async {
                  await data.applyTo(
                    ref.read(comicRepoProvider),
                    comic.comicId,
                  );
                },
              ),
            );
          case ComicContextAction.showInExplorer:
            showInFileExplorer(comic.path).catchError((
              Object error,
              StackTrace stackTrace,
            ) {
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
                  '无法在文件资源管理器中显示该项目',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              );
            });
          case ComicContextAction.delete:
            showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('删除漫画？'),
                content: Text('将删除「${comic.title}」。此操作不可撤销。'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('删除'),
                  ),
                ],
              ),
            ).then((bool? confirmed) async {
              if (confirmed != true || !context.mounted) {
                return;
              }
              try {
                await ref.read(comicDeletionServiceProvider).deleteComics(
                  <String>[comic.comicId],
                );
                ref
                    .read(comicCoverCacheManagerProvider.notifier)
                    .clearForComics(<String>[comic.comicId]);
                if (context.mounted) {
                  showSuccessToast(context, '已删除漫画');
                }
              } catch (err) {
                if (context.mounted) {
                  showErrorToast(context, err);
                }
              }
            });
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
            color: isHover ? cs.primary : cs.hentai.textPrimary,
          ),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text(
          '$pageCount 页',
          style: TextStyle(
            fontSize: tokens.text.labelXs - 1,
            color: cs.hentai.textTertiary,
          ),
        ),
      ],
    );
  }
}
