import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_image.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/detail_primary_row_layout.dart';

/// Immersive cover header：与前景封面同源的模糊 backdrop，高度对齐封面底边。
///
/// [backdropCover] 非空时绘制 backdrop；为 null（无封面 / 未 Ready / 错误）时仅为
/// 普通表面上的 [DetailPrimaryRowLayout]。
class ImmersiveCoverHeader extends StatelessWidget {
  const ImmersiveCoverHeader({
    super.key,
    required this.cover,
    required this.content,
    this.backdropCover,
    this.coverWidth = 220,
    this.coverAspectRatio = 2 / 3,
    this.contentPadding = EdgeInsets.zero,
  });

  /// Test / finder key for the blurred backdrop band.
  static const Key backdropKey = Key('immersive_cover_header_backdrop');

  /// Same cover image as the foreground. Null → no backdrop.
  final ComicCoverImage? backdropCover;

  final Widget cover;
  final Widget content;
  final double coverWidth;
  final double coverAspectRatio;

  /// Applied only to the foreground primary row; backdrop spans this widget's
  /// full width (main content pane).
  final EdgeInsetsGeometry contentPadding;

  double get _coverHeight => coverWidth / coverAspectRatio;

  @override
  Widget build(BuildContext context) {
    final ComicCoverImage? backdrop = backdropCover;
    final Widget foreground = Padding(
      padding: contentPadding,
      child: DetailPrimaryRowLayout(
        cover: cover,
        content: content,
        coverWidth: coverWidth,
      ),
    );

    if (backdrop == null) {
      return foreground;
    }

    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double fadeExtent = tokens.spacing.xl + tokens.spacing.sm;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _coverHeight,
          child: ImmersiveCoverHeaderBackdrop(
            key: backdropKey,
            coverImage: backdrop,
            surfaceColor: cs.surface,
            fadeExtent: fadeExtent,
          ),
        ),
        foreground,
      ],
    );
  }
}

/// Observable backdrop band for Immersive cover header (blur + scrim + fade).
class ImmersiveCoverHeaderBackdrop extends StatelessWidget {
  const ImmersiveCoverHeaderBackdrop({
    super.key,
    required this.coverImage,
    required this.surfaceColor,
    required this.fadeExtent,
    this.blurSigma = 28,
    this.scrimOpacity = 0.28,
  });

  final ComicCoverImage coverImage;
  final Color surfaceColor;
  final double fadeExtent;
  final double blurSigma;
  final double scrimOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: Transform.scale(
              scale: 1.12,
              child: AppComicImage(
                memoryBytes: coverImage.memoryBytes,
                filePath: coverImage.filePath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                placeholder: const SizedBox.expand(),
                errorPlaceholder: const SizedBox.expand(),
              ),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: scrimOpacity)),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: fadeExtent,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      surfaceColor.withValues(alpha: 0),
                      surfaceColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
