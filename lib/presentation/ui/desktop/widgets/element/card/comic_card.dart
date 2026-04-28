import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/usecases/purge_comics_side_effects.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/context_menu/comic_context_menu.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/edit_metadata_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/app_comic_image.dart';
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
    final ComicCoverDisplayData? coverData = ref
        .watch(comicCoverDisplayProvider(comicId: comic.comicId))
        .maybeWhen(data: (ComicCoverDisplayData? v) => v, orElse: () => null);

    return GestureDetector(
      onTap: onTap,
      onSecondaryTapUp: (details) {
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final Offset relativePosition = overlay.globalToLocal(
          details.globalPosition,
        );

        ComicContextMenu.show(
          context,
          position: relativePosition,
          mangaTitle: comic.title,
          onAction: (action) {
            switch (action) {
              case ComicContextAction.read:
                appRouter.pushNamed(
                  ReaderRouteArgs.readerRouteName,
                  queryParameters: ReaderRouteArgs(
                    comicId: comic.comicId,
                    readType: ReaderRouteArgs.readTypeComic,
                  ).toQueryParameters(),
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
                      showSuccessToast(context, '已删除漫画');
                    }
                  } catch (err) {
                    if (context.mounted) {
                      showErrorToast(context, err);
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
              _buildCover(context, coverData, isHover.value),
              // --- 文本信息区域 ---
              _buildInfoSection(isHover.value, context, comic.pageCount ?? 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(
    BuildContext context,
    ComicCoverDisplayData? coverData,
    bool isHover,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final int coverCacheWidth = AppComicImage.resolveCacheWidth(
      context: context,
      logicalWidth: 320,
      maxWidth: 1024,
    );
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
              AppComicImage(
                    filePath: coverData?.filePath,
                    memoryBytes: coverData?.memoryBytes,
                    fit: BoxFit.cover,
                    cacheWidth: coverCacheWidth,
                    placeholder: Container(
                      color: cs.imageFallback,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: cs.iconSecondary),
                    ),
                    errorPlaceholder: Container(
                      color: cs.imageFallback,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: cs.iconSecondary),
                    ),
                  )
                  .animate(target: isHover ? 1 : 0)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutQuad,
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
