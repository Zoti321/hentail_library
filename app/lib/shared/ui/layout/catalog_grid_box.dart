import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 盒模型目录网格（shrinkWrap）：供同级内容 [PeerContentTransition] 等非 sliver 壳使用。
///
/// 水平留白由外层负责时传 [horizontalMargin] `0`。
class CatalogGridBox extends StatelessWidget {
  const CatalogGridBox({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.horizontalMargin = 0,
    this.hasSubtitle = true,
  });

  final int itemCount;
  final CatalogGridItemBuilder itemBuilder;
  final double horizontalMargin;
  final bool hasSubtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final M3ESpacing spacing = M3ETheme.of(context).spacing;
        final CatalogGridLayout layout = CatalogGridMetrics.resolve(
          viewportWidth: constraints.maxWidth,
          spacing: spacing,
          horizontalMargin: horizontalMargin,
          hasSubtitle: hasSubtitle,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalMargin),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: catalogGridDelegate(layout),
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return CatalogGridCell(
                child: itemBuilder(context, index, layout),
              );
            },
          ),
        );
      },
    );
  }
}
