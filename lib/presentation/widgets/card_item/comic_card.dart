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
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/context_menu.dart';
import 'package:hentai_library/presentation/widgets/dialog/edit_metadata_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicCard extends HookConsumerWidget {
  final Comic comic;
  final Size size;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const ComicCard({
    super.key,
    required this.comic,
    required this.size,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final isHover = useState<bool>(false);
    final coverPath = ref
        .watch(comicCoverPathProvider(comicId: comic.comicId))
        .maybeWhen(data: (v) => v, orElse: () => null);

    return GestureDetector(
      onTap: onTap,
      onSecondaryTapUp: (details) {
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final Offset relativePosition = overlay.globalToLocal(
          details.globalPosition,
        );

        FluentContextMenu.show(
          context,
          position: relativePosition,
          mangaTitle: comic.title,
          onAction: (action) {
            switch (action) {
              case ComicContextAction.read:
                appRouter.pushNamed(
                  "阅读页面",
                  pathParameters: {'id': comic.comicId},
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
                  builder: (context) => EditMetadataDialog(
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
                if (coverPath != null) openFolder(coverPath);
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
                      libraryComics: ref.read(libraryComicRepoProvider),
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
      }, // 右键菜单触发

      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => isHover.value = true,
        onExit: (_) => isHover.value = false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(tokens.spacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radius.lg),
            color: cs.surface,
            border: Border.all(color: cs.borderSubtle),
            boxShadow: isHover.value
                ? [
                    BoxShadow(
                      color: cs.cardShadowHover,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              // 封面图容器
              _buildCover(context, coverPath, isHover.value),
              // --- 文本信息区域 ---
              _buildInfoSection(isHover.value, context, comic.pageCount ?? 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, String? coverPath, bool isHover) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        color: cs.imagePlaceholder,
        boxShadow: isHover
            ? [
                BoxShadow(
                  color: cs.cardShadowHover,
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ]
            : [
                BoxShadow(
                  color: cs.cardShadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 图片 + 缩放动画
              if (coverPath != null)
                ExtendedImage.file(File(coverPath), fit: BoxFit.cover)
                    .animate(target: isHover ? 1 : 0)
                    .scale(
                      begin: Offset(1, 1),
                      end: Offset(1.05, 1.05),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuad,
                    )
              else
                Container(
                  color: cs.imageFallback,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image, color: cs.iconSecondary),
                ),

              // 2. 黑色遮罩层 (Hover 时显示)
              Container(color: cs.overlayScrim)
                  .animate(target: isHover ? 1 : 0)
                  .fade(begin: 0.0, end: 1.0, duration: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildInfoSection(bool isHover, BuildContext context, int pageCount) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        // 标题 (带 Hover 变色)
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: tokens.text.bodyMd,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: isHover
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.textPrimary,
          ),
          child: Text(
            comic.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 底部信息栏
        Row(
          children: [
            Text(
              '$pageCount页',
              style: TextStyle(
                fontSize: tokens.text.labelXs - 1,
                color: Theme.of(context).colorScheme.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
