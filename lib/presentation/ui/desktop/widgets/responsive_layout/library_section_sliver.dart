import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';

/// 复用系列/漫画区块共同的 section 外壳（标题、内边距、尾部间距）。
class LibrarySectionSliver extends StatelessWidget {
  const LibrarySectionSliver({
    super.key,
    required this.title,
    required this.contentSliver,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 48, vertical: 2),
    this.bottomSpacing,
  });

  final String title;
  final Widget contentSliver;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry contentPadding;
  final double? bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: headerPadding,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: contentPadding,
          sliver: contentSliver,
        ),
        if (bottomSpacing != null)
          SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
      ],
    );
  }
}

/// 复用系列/漫画区块“网格/列表切换”的公共壳层。
class LibraryAdaptiveItemsSliver extends StatelessWidget {
  const LibraryAdaptiveItemsSliver({
    super.key,
    required this.isGridView,
    required this.gridSliver,
    required this.listSliver,
  });

  final bool isGridView;
  final Widget gridSliver;
  final Widget listSliver;

  @override
  Widget build(BuildContext context) {
    return isGridView ? gridSliver : listSliver;
  }
}
