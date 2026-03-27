import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/context_menu.dart';
import 'package:hentai_library/presentation/widgets/dialog/edit_metadata_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicCard extends HookConsumerWidget {
  final LibraryComic comic;
  final Size size;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final Function(TapDownDetails) onRightClick;

  const ComicCard({
    super.key,
    required this.comic,
    required this.size,
    required this.onTap,
    required this.onPlay,
    required this.onRightClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHover = useState<bool>(false);
    final coverPath = ref
        .watch(comicCoverPathProvider(comicId: comic.comicId))
        .maybeWhen(data: (v) => v, orElse: () => null);
    final pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(data: (files) => files.length, orElse: () => 0);

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
              case 'read':
                appRouter.pushNamed(
                  "阅读页面",
                  pathParameters: {'id': comic.comicId},
                );
                break;
              case 'detail':
                appRouter.pushNamed(
                  '漫画详情',
                  pathParameters: {'id': comic.comicId},
                );
                break;
              case "edit":
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
              case "merge":
                // 章节归档功能已下线。
                break;
              case "open_folder":
                if (coverPath != null) openFolder(coverPath);
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: isHover.value
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
              _buildCover(coverPath, isHover.value),
              // --- 文本信息区域 ---
              _buildInfoSection(isHover.value, context, pageCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String? coverPath, bool isHover) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200], // 占位背景
        boxShadow: isHover
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ]
            : [
                // shadow-sm
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 图片 + 缩放动画
              if (coverPath != null)
                ExtendedImage.file(
                      File(coverPath),
                      cacheWidth: 200,
                      fit: BoxFit.cover,
                    )
                    .animate(target: isHover ? 1 : 0)
                    .scale(
                      begin: Offset(1, 1),
                      end: Offset(1.05, 1.05),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuad,
                    )
              else
                Container(
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                ),

              // 2. 黑色遮罩层 (Hover 时显示)
              Container(color: Colors.black.withAlpha(20))
                  .animate(target: isHover ? 1 : 0)
                  .fade(begin: 0.0, end: 1.0, duration: 200.ms),

              // 3. 格式标签 (右上角)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withAlpha(10)),
                  ),
                  child: Text(
                    comic.resourceType.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildInfoSection(bool isHover, BuildContext context, int pageCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        // 标题 (带 Hover 变色)
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 14,
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
              '${pageCount}p',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
