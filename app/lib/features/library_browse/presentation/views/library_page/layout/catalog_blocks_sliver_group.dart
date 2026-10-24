import 'package:flutter/widgets.dart';

/// 复用「系列区块 + 漫画区块」的 Library catalog 页 sliver 组合。
class CatalogBlocksSliverGroup extends StatelessWidget {
  const CatalogBlocksSliverGroup({
    super.key,
    required this.seriesBlock,
    required this.comicsBlock,
  });

  final Widget seriesBlock;
  final Widget comicsBlock;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: <Widget>[seriesBlock, comicsBlock]);
  }
}
