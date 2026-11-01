import 'package:flutter/material.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport_status.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_tap_zone.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport_placeholder.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport_status_panel.dart';

/// 阅读画布手势层：三分区点击（chrome 显隐与翻页由外层处理）。
class Md3eReaderViewport extends StatelessWidget {
  const Md3eReaderViewport({
    super.key,
    required this.currentPage,
    this.onTapZone,
    this.focusNode,
    this.status = Md3eReaderViewportStatus.ready,
    this.onBack,
    this.onRetry,
  });

  final int currentPage;

  /// 为空时点击不产生分区回调（生产页由内容层自行处理点击）。
  final ValueChanged<Md3eReaderTapZone>? onTapZone;
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
          onTapZone?.call(Md3eReaderTapZone.center);
          return;
        }
        final Offset local = box.globalToLocal(details.globalPosition);
        onTapZone?.call(
          md3eResolveReaderTapZone(localX: local.dx, width: box.size.width),
        );
      },
      child: switch (status) {
        Md3eReaderViewportStatus.ready => Md3eReaderViewportPlaceholder(
          page: currentPage,
        ),
        Md3eReaderViewportStatus.loading => const Md3eReaderViewportLoading(),
        Md3eReaderViewportStatus.error => Md3eReaderViewportErrorPanel(
          onBack: onBack,
          onRetry: onRetry,
        ),
      },
    );
  }
}
