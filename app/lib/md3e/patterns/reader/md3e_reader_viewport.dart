import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_viewport_placeholder.dart';

/// 阅读画布手势层：三分区点击（chrome 显隐与翻页由外层处理）。
class Md3eReaderViewport extends StatelessWidget {
  const Md3eReaderViewport({
    super.key,
    required this.currentPage,
    required this.chromeVisible,
    required this.onTapZone,
    this.focusNode,
  });

  final int currentPage;
  final bool chromeVisible;
  final ValueChanged<Md3eReaderTapZone> onTapZone;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) {
        focusNode?.requestFocus();
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box == null) {
          onTapZone(Md3eReaderTapZone.center);
          return;
        }
        final Offset local = box.globalToLocal(details.globalPosition);
        onTapZone(
          md3eResolveReaderTapZone(
            localX: local.dx,
            width: box.size.width,
          ),
        );
      },
      child: Md3eReaderViewportPlaceholder(
        page: currentPage,
        showEdgeHints: !chromeVisible,
      ),
    );
  }
}
