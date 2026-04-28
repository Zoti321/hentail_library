import 'package:flutter/material.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'series_comic_list_row.dart';

class SeriesComicItemsCard extends StatelessWidget {
  const SeriesComicItemsCard({
    super.key,
    required this.colorScheme,
    required this.listCardRadius,
    required this.sortedItems,
    required this.seriesName,
  });
  final ColorScheme colorScheme;
  final double listCardRadius;
  final List<SeriesItem> sortedItems;
  final String seriesName;
  @override
  Widget build(BuildContext context) {
    // 空数据边缘情况处理
    if (sortedItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(),
          Expanded(
            child: _SeriesComicItemsEmptyListArea(
              colorScheme: colorScheme,
              listCardRadius: listCardRadius,
            ),
          ),
        ],
      );
    }

    final int itemCount = sortedItems.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: .circular(listCardRadius),
        border: Border.all(color: colorScheme.borderSubtle),
      ),
      clipBehavior: .antiAlias,
      child: ClipRRect(
        borderRadius: .circular(listCardRadius),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            // header
            _buildHeader(),
            // 滚动区域列表
            Flexible(
              child: ListView.separated(
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                itemCount: itemCount,
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(height: 1, color: colorScheme.borderSubtle);
                },
                itemBuilder: (BuildContext context, int index) {
                  return SeriesItemComicTile(
                    item: sortedItems[index],
                    sequenceNumber: index + 1,
                    seriesName: seriesName,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildHeader() {
    return Container(
      padding: .symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: .only(
          topLeft: .circular(listCardRadius),
          topRight: .circular(listCardRadius),
        ),
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.borderSubtle)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            LucideIcons.bookOpen,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '系列内漫画',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesComicItemsEmptyListArea extends StatelessWidget {
  const _SeriesComicItemsEmptyListArea({
    required this.colorScheme,
    required this.listCardRadius,
  });
  final ColorScheme colorScheme;
  final double listCardRadius;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.borderSubtle),
          right: BorderSide(color: colorScheme.borderSubtle),
          bottom: BorderSide(color: colorScheme.borderSubtle),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(listCardRadius),
          bottomRight: Radius.circular(listCardRadius),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Text(
            '暂无漫画，点击「添加漫画」加入',
            style: TextStyle(fontSize: 14, color: colorScheme.textTertiary),
          ),
        ),
      ),
    );
  }
}
