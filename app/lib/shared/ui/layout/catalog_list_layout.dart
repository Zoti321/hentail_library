import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/platform_desktop.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// List column count for catalog browse, from window size class and platform.
///
/// Compact (phone portrait) is always one column. Desktop packs more columns
/// because the window is wide and rows are short; mobile tablets stay sparser.
///
/// | size class | desktop | mobile |
/// | ---------- | ------- | ------ |
/// | compact    | 1       | 1      |
/// | medium     | 2       | 2      |
/// | expanded   | 3       | 2      |
/// | large      | 4       | 3      |
/// | extraLarge | 4       | 3      |
///
/// [desktop] defaults to the running platform ([isDesktop]).
int comicListColumnCount(WindowSizeClass window, {bool? desktop}) {
  final bool isDesktopLayout = desktop ?? isDesktop;
  switch (window) {
    case WindowSizeClass.compact:
      return 1;
    case WindowSizeClass.medium:
      return 2;
    case WindowSizeClass.expanded:
      return isDesktopLayout ? 3 : 2;
    case WindowSizeClass.large:
      return isDesktopLayout ? 4 : 3;
    case WindowSizeClass.extraLarge:
      return isDesktopLayout ? 4 : 3;
  }
}

/// 懒构建的多列目录列表（行级 [SliverChildBuilderDelegate]）。
class CatalogListSliver extends StatelessWidget {
  const CatalogListSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final int columns = comicListColumnCount(layout.sizeClass);
    if (columns <= 1) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == itemCount - 1 ? 0 : layout.listItemGap,
            ),
            child: itemBuilder(context, index),
          );
        }, childCount: itemCount),
      );
    }

    final int rowCount = (itemCount + columns - 1) ~/ columns;
    return SliverList(
      delegate: SliverChildBuilderDelegate((
        BuildContext context,
        int rowIndex,
      ) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIndex == rowCount - 1 ? 0 : layout.listItemGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int column = 0; column < columns; column++) ...<Widget>[
                if (column > 0) SizedBox(width: layout.listItemGap),
                Expanded(
                  child: rowIndex * columns + column < itemCount
                      ? itemBuilder(context, rowIndex * columns + column)!
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      }, childCount: rowCount),
    );
  }
}
