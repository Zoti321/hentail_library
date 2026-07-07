import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SeriesCard extends HookConsumerWidget {
  final Series series;
  final Size size;
  final VoidCallback? onTap;
  final void Function(TapDownDetails details)? onSecondaryTapDown;

  const SeriesCard({
    super.key,
    required this.series,
    required this.size,
    this.onTap,
    this.onSecondaryTapDown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final isHover = useState<bool>(false);
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final int count = series.items.length;
    final Widget content = GestureDetector(
      onTap: onTap,
      onSecondaryTapDown: onSecondaryTapDown,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => isHover.value = true,
        onExit: (_) => isHover.value = false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(tokens.spacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radius.lg),
            color: cs.surface,
            border: Border.all(color: cs.hentai.borderSubtle),
            boxShadow: isHover.value
                ? <BoxShadow>[
                    BoxShadow(
                      color: cs.hentai.cardShadowHover,
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
            children: <Widget>[
              _SeriesCardCover(
                coverComicId: coverComicId,
                isHover: isHover.value,
              ),
              _SeriesCardInfo(
                series: series,
                count: count,
                isHover: isHover.value,
              ),
            ],
          ),
        ),
      ),
    );
    if (size.width.isFinite) {
      return SizedBox(width: size.width, child: content);
    }
    return content;
  }
}

class _SeriesCardCover extends StatelessWidget {
  const _SeriesCardCover({required this.coverComicId, required this.isHover});

  final String? coverComicId;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        color: cs.hentai.imagePlaceholder,
        boxShadow: isHover
            ? <BoxShadow>[
                BoxShadow(
                  color: cs.hentai.cardShadowHover,
                  blurRadius: 20,
                  offset: Offset.zero,
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color: cs.hentai.cardShadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: coverComicId != null
              ? ComicCoverContent(comicId: coverComicId!, isHover: isHover)
              : const ComicCoverPlaceholder(
                  variant: ComicCoverPlaceholderVariant.card,
                  kind: ComicCoverPlaceholderKind.noCover,
                ),
        ),
      ),
    );
  }
}

class _SeriesCardInfo extends StatelessWidget {
  const _SeriesCardInfo({
    required this.series,
    required this.count,
    required this.isHover,
  });

  final Series series;
  final int count;
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
          child: Text(
            series.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          series.volumeCountLabel,
          style: TextStyle(
            fontSize: tokens.text.labelXs - 1,
            color: cs.hentai.textTertiary,
          ),
        ),
      ],
    );
  }
}
