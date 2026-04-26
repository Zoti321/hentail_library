import 'package:flutter/widgets.dart';

/// 复用“系列区块 + 漫画区块”的页面级 sliver 组合。
class LibraryBlocksSliverGroup extends StatelessWidget {
  const LibraryBlocksSliverGroup({
    super.key,
    required this.seriesBlock,
    required this.comicsBlock,
  });

  final Widget seriesBlock;
  final Widget comicsBlock;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: <Widget>[
        seriesBlock,
        comicsBlock,
      ],
    );
  }
}
