import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';

/// 已删除列表 sliver：列数与库页列表视图一致（expanded 桌面端 3 列）。
class TrashListSliver extends StatelessWidget {
  const TrashListSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final int columns = comicListColumnCount(layout.sizeClass);
    final double gap = layout.listItemGap;

    if (itemCount <= 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (columns == 1) {
      return SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: itemBuilder(context, index),
          );
        },
      );
    }

    final int rowCount = (itemCount + columns - 1) ~/ columns;
    return SliverList.builder(
      itemCount: rowCount,
      itemBuilder: (BuildContext context, int rowIndex) {
        final int firstIndex = rowIndex * columns;
        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int column = 0; column < columns; column++) ...<Widget>[
                if (column > 0) SizedBox(width: gap),
                Expanded(
                  child: firstIndex + column < itemCount
                      ? itemBuilder(context, firstIndex + column)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
