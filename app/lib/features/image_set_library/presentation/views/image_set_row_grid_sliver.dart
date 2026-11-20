import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_image_tile.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Virtualized Image set detail gallery (SliverGrid).
///
/// Cell geometry reserves a fixed affinity strip band above a 2:3 image body so
/// a later reorder ticket can keep stable [ValueKey]s without rewriting the grid.
class ImageSetRowGridSliver extends StatelessWidget {
  const ImageSetRowGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, constraints) {
        final M3ESpacing spacing = M3ETheme.of(context).spacing;
        final CatalogGridLayout layout = CatalogGridMetrics.resolve(
          viewportWidth: constraints.crossAxisExtent,
          spacing: spacing,
          hasSubtitle: false,
        );
        final double imageHeight =
            layout.cellWidth / kImageSetGalleryAspectRatio;
        final double mainAxisExtent =
            kImageSetAffinityStripBandHeight + imageHeight;

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalMargin),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: layout.crossAxisCount,
              mainAxisExtent: mainAxisExtent,
              crossAxisSpacing: layout.gutter,
              mainAxisSpacing: layout.gutter,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => itemBuilder(context, index),
              childCount: itemCount,
              addAutomaticKeepAlives: false,
            ),
          ),
        );
      },
    );
  }
}
