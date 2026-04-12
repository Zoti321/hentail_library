import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/usecases/purge_comics_side_effects.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/routes/routes.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/context_menu.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/edit_metadata_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicTile extends HookConsumerWidget {
  final Comic comic;
  final VoidCallback onTap;

  const ComicTile({super.key, required this.comic, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isHovered = useState(false);
    final coverPath = ref
        .watch(comicCoverPathProvider(comicId: comic.comicId))
        .maybeWhen(data: (v) => v, orElse: () => null);
    final pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(data: (files) => files.length, orElse: () => 0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,

      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapUp: (TapUpDetails details) {
          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          final Offset relativePosition = overlay.globalToLocal(
            details.globalPosition,
          );
          FluentContextMenu.show(
            context,
            position: relativePosition,
            mangaTitle: comic.title,
            onAction: (ComicContextAction action) {
              switch (action) {
                case ComicContextAction.read:
                  appRouter.pushNamed(
                    '阅读页面',
                    queryParameters: {
                      'read_type': 'comic',
                      'comic_id': comic.comicId,
                    },
                  );
                  break;
                case ComicContextAction.detail:
                  appRouter.pushNamed(
                    '漫画详情',
                    pathParameters: {'id': comic.comicId},
                  );
                  break;
                case ComicContextAction.edit:
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => EditMetadataDialog(
                      comic: comic,
                      onSave: (data) async {
                        await ref.read(updateComicMetadataUseCaseProvider)(
                          comic.comicId,
                          data,
                        );
                      },
                    ),
                  );
                  break;
                case ComicContextAction.openFolder:
                  if (coverPath != null) {
                    openFolder(coverPath);
                  }
                  break;
                case ComicContextAction.delete:
                  showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('删除漫画？'),
                      content: Text('将删除「${comic.title}」。此操作不可撤销。'),
                      actions: [
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
                      await purgeComicsFromApp(
                        libraryComics: ref.read(comicRepoProvider),
                        readingHistory: ref.read(readingHistoryRepoProvider),
                        librarySeries: ref.read(librarySeriesRepoProvider),
                        comicIds: <String>[comic.comicId],
                      );
                      if (context.mounted) {
                        showSuccessSnackBar(context, '已删除漫画');
                      }
                    } catch (err) {
                      if (context.mounted) {
                        showErrorSnackBar(context, err);
                      }
                    }
                  });
                  break;
              }
            },
          );
        },

        child: Container(
          margin: EdgeInsets.only(bottom: tokens.spacing.md),
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.sm,
            tokens.spacing.sm,
            tokens.spacing.lg,
            tokens.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: isHovered.value
                ? theme.colorScheme.surfaceContainer
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            border: Border.all(color: theme.colorScheme.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              // 封面图片
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius.sm),
                child: Container(
                  width: 56,
                  height: 80,
                  color: theme.colorScheme.imagePlaceholder,
                  child: coverPath != null
                      ? ExtendedImage.file(
                          File(coverPath),
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        )
                      : Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.iconSecondary,
                        ),
                ),
              ),
              SizedBox(width: tokens.spacing.lg),

              // --- 文本信息 ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Text(
                      comic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: tokens.text.bodyMd,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.xs - 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.subtleTagBackground,
                            borderRadius: BorderRadius.circular(
                              tokens.radius.xs,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            comic.resourceType.name,
                            style: TextStyle(
                              fontSize: tokens.text.labelXs - 1,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: tokens.spacing.md),
                        Text(
                          '${pageCount}p',
                          style: TextStyle(
                            fontSize: tokens.text.labelXs,
                            color: theme.colorScheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(target: isHovered.value ? 1 : 0),
      ),
    );
  }
}
