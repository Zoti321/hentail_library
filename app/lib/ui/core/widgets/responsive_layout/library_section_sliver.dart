import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// 复用系列/漫画区块共同的 section 外壳（标题、内边距、尾部间距）。
class LibrarySectionSliver extends StatelessWidget {
  const LibrarySectionSliver({
    super.key,
    required this.title,
    required this.contentSliver,
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: 48,
      vertical: 4,
    ),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 48,
      vertical: 2,
    ),
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
                color: Theme.of(context).colorScheme.hentai.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(padding: contentPadding, sliver: contentSliver),
        if (bottomSpacing != null)
          SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
      ],
    );
  }
}
