import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid_metrics.dart';
import 'package:hentai_library/md3e/widgets/md3e_comic_card.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// Fake catalog grid for MD3E Lab / Widgetbook (no domain types).
class Md3eLibraryBrowsePreviewView extends StatelessWidget {
  const Md3eLibraryBrowsePreviewView({super.key, this.itemCount = 12});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing tokens = M3ETheme.of(context).spacing;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Md3eWindowSizeClass window = md3eWindowSizeClassOf(context);
    final double cellWidth = Md3eCatalogGridMetrics.maxCrossAxisExtent(window);
    final double gridSpacing = Md3eCatalogGridMetrics.gridSpacing(window);

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.all(tokens.lg),
          sliver: SliverToBoxAdapter(
            child: Text(
              '书库预览',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.lg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: cellWidth,
              mainAxisExtent: Md3eComicCard.gridMainAxisExtent(
                maxCrossAxisExtent: cellWidth,
                coverToInfoGap: tokens.md,
                infoBottomPadding: tokens.sm,
              ),
              mainAxisSpacing: gridSpacing,
              crossAxisSpacing: gridSpacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final double? readProgress = index.isOdd
                    ? null
                    : ((index % 9) + 1) / 10;
                return Md3eComicCard(
                  title: '示例本子 ${index + 1}',
                  subtitle: '${64 + index * 8} 页',
                  readProgress: readProgress,
                  cover: ColoredBox(
                    color: scheme.surfaceContainerHigh,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  onTap: () {},
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}
