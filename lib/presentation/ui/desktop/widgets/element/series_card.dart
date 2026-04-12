import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SeriesCard extends HookConsumerWidget {
  final Series series;
  final Size size;
  final VoidCallback? onTap;

  const SeriesCard({
    super.key,
    required this.series,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final isHover = useState<bool>(false);
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final String? coverPath = coverComicId != null
        ? ref
              .watch(comicCoverPathProvider(comicId: coverComicId))
              .maybeWhen(data: (String? v) => v, orElse: () => null)
        : null;
    final int count = series.items.length;
    final Widget content = GestureDetector(
      onTap: onTap,
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
            border: Border.all(color: cs.borderSubtle),
            boxShadow: isHover.value
                ? <BoxShadow>[
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
            children: <Widget>[
              _SeriesCardCover(
                series: series,
                coverPath: coverPath,
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
  const _SeriesCardCover({
    required this.series,
    required this.coverPath,
    required this.isHover,
  });

  final Series series;
  final String? coverPath;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String? resolvedPath = coverPath;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        color: cs.imagePlaceholder,
        boxShadow: isHover
            ? <BoxShadow>[
                BoxShadow(
                  color: cs.cardShadowHover,
                  blurRadius: 20,
                  offset: Offset.zero,
                ),
              ]
            : <BoxShadow>[
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
            children: <Widget>[
              if (resolvedPath != null)
                ExtendedImage.file(File(resolvedPath), fit: BoxFit.cover)
                    .animate(target: isHover ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuad,
                    )
              else
                Container(
                  color: cs.imageFallback,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image, color: cs.iconSecondary),
                ),
              Container(color: cs.overlayScrim)
                  .animate(target: isHover ? 1 : 0)
                  .fade(begin: 0.0, end: 1.0, duration: 200.ms),
              Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        series.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: tokens.text.bodySm,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                          shadows: <Shadow>[
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.85),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate(target: isHover ? 1 : 0)
                  .fade(begin: 0.0, end: 1.0, duration: 200.ms),
            ],
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
            height: 1.25,
            color: isHover ? cs.primary : cs.textPrimary,
          ),
          child: Text(
            series.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '包含 $count 本',
          style: TextStyle(
            fontSize: tokens.text.labelXs - 1,
            color: cs.textTertiary,
          ),
        ),
      ],
    );
  }
}
