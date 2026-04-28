import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/app_comic_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SeriesTile extends HookConsumerWidget {
  final Series series;
  final VoidCallback onTap;
  final void Function(TapDownDetails details) onSecondaryTapDown;
  final Widget? trailing;

  const SeriesTile({
    super.key,
    required this.series,
    required this.onTap,
    required this.onSecondaryTapDown,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final isHovered = useState<bool>(false);
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final ComicCoverDisplayData? coverData = coverComicId != null
        ? ref
              .watch(comicCoverDisplayProvider(comicId: coverComicId))
              .maybeWhen(
                data: (ComicCoverDisplayData? v) => v,
                orElse: () => null,
              )
        : null;
    final int count = series.items.length;
    final int coverCacheWidth = AppComicImage.resolveCacheWidth(
      context: context,
      logicalWidth: 56 * 3,
      maxWidth: 768,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapDown: onSecondaryTapDown,
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
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius.sm),
                child: Container(
                  width: 56,
                  height: 80,
                  color: theme.colorScheme.imagePlaceholder,
                  child: AppComicImage(
                    filePath: coverData?.filePath,
                    memoryBytes: coverData?.memoryBytes,
                    fit: BoxFit.cover,
                    cacheWidth: coverCacheWidth,
                    placeholder: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.iconSecondary,
                    ),
                    errorPlaceholder: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.iconSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: tokens.spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Tooltip(
                      message: series.name,
                      child: Text(
                        series.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: tokens.text.bodyMd,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.spacing.xs - 2),
                    Text(
                      '包含 $count 本',
                      style: TextStyle(
                        fontSize: tokens.text.labelXs,
                        color: theme.colorScheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ).animate(target: isHovered.value ? 1 : 0),
      ),
    );
  }
}
