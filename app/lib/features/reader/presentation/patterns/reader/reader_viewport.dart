import 'package:flutter/material.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_viewport_status.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_tap_zone.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_viewport_placeholder.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_viewport_status_panel.dart';

/// 阅读画布手势层：三分区点击（chrome 显隐与翻页由外层处理）。
class ReaderViewport extends StatelessWidget {
  const ReaderViewport({
    super.key,
    required this.currentPage,
    this.onTapZone,
    this.focusNode,
    this.status = ReaderViewportStatus.ready,
    this.onBack,
    this.onRetry,
  });

  final int currentPage;

  /// 为空时点击不产生分区回调（生产页由内容层自行处理点击）。
  final ValueChanged<ReaderViewportTapZone>? onTapZone;
  final FocusNode? focusNode;
  final ReaderViewportStatus status;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (TapUpDetails details) => _handleTapUp(context, details),
      child: switch (status) {
        ReaderViewportStatus.ready => ReaderViewportPlaceholder(
          page: currentPage,
        ),
        ReaderViewportStatus.loading => const ReaderViewportLoading(),
        ReaderViewportStatus.error => ReaderViewportErrorPanel(
          onBack: onBack,
          onRetry: onRetry,
        ),
      },
    );
  }

  void _handleTapUp(BuildContext context, TapUpDetails details) {
    focusNode?.requestFocus();
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      onTapZone?.call(ReaderViewportTapZone.center);
      return;
    }
    final Offset local = box.globalToLocal(details.globalPosition);
    onTapZone?.call(
      resolveReaderViewportTapZone(localX: local.dx, width: box.size.width),
    );
  }
}
