import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_list_layout.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_list_item.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// Fake catalog list for MD3E Lab / Widgetbook (no domain types).
class Md3eLibraryBrowseListPreviewView extends StatelessWidget {
  const Md3eLibraryBrowseListPreviewView({super.key, this.itemCount = 12});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Md3eWindowSizeClass window = md3eWindowSizeClassOf(context);
    final int columns = md3eComicListColumnCount(window);

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.all(spacing.lg),
          sliver: SliverToBoxAdapter(
            child: Text(
              '书库列表预览',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        if (columns == 1)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) =>
                  _buildItem(context, scheme, index),
              childCount: itemCount,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int rowIndex) {
                final int leftIndex = rowIndex * 2;
                final int rightIndex = leftIndex + 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _buildItem(context, scheme, leftIndex),
                    ),
                    Expanded(
                      child: rightIndex < itemCount
                          ? _buildItem(context, scheme, rightIndex)
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              childCount: (itemCount + 1) ~/ 2,
            ),
          ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, ColorScheme scheme, int index) {
    final double? readProgress =
        index.isOdd ? null : ((index % 9) + 1) / 10;
    return Md3eComicListItem(
      title: '示例本子 ${index + 1}',
      author: '作者 ${index % 5 + 1}',
      pageLabel: '${64 + index * 8} 页',
      readProgress: readProgress,
      moreMenuEntries: const <Md3eComicListMoreMenuEntry>[
        Md3eComicListMoreMenuEntry(label: '继续阅读'),
        Md3eComicListMoreMenuEntry(label: '编辑元数据'),
        Md3eComicListMoreMenuEntry(label: '删除'),
      ],
      cover: ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
      onTap: () {},
    );
  }
}
