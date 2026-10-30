import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_preview_data.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_viewport_placeholder.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_viewport_status_panel.dart';

/// 阅读画布手势层：三分区点击（chrome 显隐与翻页由外层处理）。
class Md3eReaderViewport extends StatelessWidget {
  const Md3eReaderViewport({
    super.key,
    required this.currentPage,
    required this.onTapZone,
    this.focusNode,
    this.status = Md3eReaderViewportStatus.ready,
    this.onBack,
    this.onRetry,
  });

  final int currentPage;
  final ValueChanged<Md3eReaderTapZone> onTapZone;
  final FocusNode? focusNode;
  final Md3eReaderViewportStatus status;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;

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
      child: switch (status) {
        Md3eReaderViewportStatus.ready =>
          Md3eReaderViewportPlaceholder(page: currentPage),
        Md3eReaderViewportStatus.loading => const Md3eReaderViewportLoading(),
        Md3eReaderViewportStatus.error => Md3eReaderViewportErrorPanel(
          onBack: onBack,
          onRetry: onRetry,
        ),
      },
    );
  }
}
