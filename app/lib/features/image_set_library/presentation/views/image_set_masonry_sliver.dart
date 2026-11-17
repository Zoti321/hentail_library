import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Caption-free masonry using [CatalogGridMetrics] column breakpoints.
///
/// Tradeoff vs [CatalogGridSliver]: unequal heights cannot use fixed
/// `mainAxisExtent`, so this builds all columns in one [SliverToBoxAdapter].
/// Tile bytes still load lazily via providers; layout is not windowed.
class ImageSetMasonrySliver extends StatelessWidget {
  const ImageSetMasonrySliver({
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
        final int columnCount = layout.crossAxisCount;
        final List<List<int>> columns = List<List<int>>.generate(
          columnCount,
          (_) => <int>[],
        );
        for (int i = 0; i < itemCount; i++) {
          columns[i % columnCount].add(i);
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalMargin),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int c = 0; c < columnCount; c++) ...<Widget>[
                  if (c > 0) SizedBox(width: layout.gutter),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        for (int r = 0; r < columns[c].length; r++) ...<Widget>[
                          if (r > 0) SizedBox(height: layout.gutter),
                          itemBuilder(context, columns[c][r]),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
