import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/context_menu/series_item_context_menu.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesItemComicTile extends ConsumerWidget {
  const SeriesItemComicTile({
    super.key,
    required this.item,
    required this.sequenceNumber,
    required this.seriesName,
  });

  final SeriesItem item;
  final int sequenceNumber;
  final String seriesName;
  static const double _kTooltipIconSlot = 22;

  static String titleForComic(WidgetRef ref, String comicId) {
    final String? title = ref.read(libraryComicByIdProvider(comicId))?.title;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return comicId.length > 12 ? '${comicId.substring(0, 12)}…' : comicId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    const double thumbnailWidth = 36;
    final ComicCoverDisplayData? coverDisplay = ref
        .watch(comicCoverDisplayProvider(comicId: item.comicId))
        .maybeWhen(data: (ComicCoverDisplayData? v) => v, orElse: () => null);
    final String title = titleForComic(ref, item.comicId);
    final int rowThumbCacheWidth = AppComicImage.resolveCacheWidth(
      context: context,
      logicalWidth: thumbnailWidth,
    );
    return Material(
      color: colorScheme.surface,
      child: GestureDetector(
        onSecondaryTapUp: (TapUpDetails details) {
          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          final Offset relativePosition = overlay.globalToLocal(
            details.globalPosition,
          );

          SeriesItemContextMenu.show(
            context,
            position: relativePosition,
            comicTitle: title,
            onAction: (SeriesItemContextAction action) {
              switch (action) {
                case SeriesItemContextAction.goToDetail:
                  appRouter.pushNamed(
                    '漫画详情',
                    pathParameters: <String, String>{'id': item.comicId},
                  );
                case SeriesItemContextAction.showInExplorer:
                  final path = ref
                      .read(libraryComicByIdProvider(item.comicId))
                      ?.path;
                  if (path == null) {
                    showErrorToast(context, AppException('找不到该漫画的文件路径'));
                    return;
                  }

                  showInFileExplorer(path).catchError((
                    Object error,
                    StackTrace stackTrace,
                  ) {
                    debugPrint('showInFileExplorer failed for "$path": $error');
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
              }
            },
          );
        },
        child: InkWell(
          onTap: () {
            appRouter.pushNamed(
              ReaderRouteArgs.readerRouteName,
              queryParameters: ReaderRouteArgs(
                comicId: item.comicId,
                readType: ReaderRouteArgs.readTypeSeries,
                seriesName: seriesName,
              ).toQueryParameters(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 26,
                  child: Text(
                    '$sequenceNumber',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.hentai.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radius.sm),
                  child: Container(
                    width: thumbnailWidth,
                    height: 50,
                    color: colorScheme.hentai.imagePlaceholder,
                    child: AppComicImage(
                      memoryBytes: coverDisplay?.memoryBytes,
                      filePath: coverDisplay?.filePath,
                      fit: BoxFit.cover,
                      cacheWidth: rowThumbCacheWidth,
                      filterQuality: FilterQuality.medium,
                      placeholder: const SizedBox.expand(),
                      errorPlaceholder: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 18,
                          color: colorScheme.hentai.iconSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTitleWithTooltip(
                    context: context,
                    title: title,
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.hentai.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWithTooltip({
    required BuildContext context,
    required String title,
    required TextStyle textStyle,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextDirection direction = Directionality.of(context);
        final TextPainter probe = TextPainter(
          text: TextSpan(text: title, style: textStyle),
          maxLines: 1,
          textDirection: direction,
        )..layout(maxWidth: constraints.maxWidth);
        final bool isTruncated = probe.didExceedMaxLines;
        if (!isTruncated) {
          return Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          );
        }
        return Row(
          children: <Widget>[
            SizedBox(
              width: math.max(0, constraints.maxWidth - _kTooltipIconSlot),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            Tooltip(
              message: title,
              waitDuration: const Duration(milliseconds: 400),
              showDuration: const Duration(seconds: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  LucideIcons.info,
                  size: 14,
                  color: colorScheme.hentai.textTertiary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
