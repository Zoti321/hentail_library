import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

export 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_list_sliver.dart';
export 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';

/// 阅读历史卡片网格（盒模型）：按宽度决定 1–3 列，**固定行高虚拟化**。
///
/// 对外以公式给出整组高度，供时间分组 [SpringExpandPanel] 的 `heightFactor`
/// 动画量测；对内只挂载落入外层 [Scrollable] 可见区（含 cache）的行，
/// 避免大桶展开时一次性创建全部卡片 Element。
///
/// 水平留白由外层负责。
class ReadingHistoryListGrid extends StatelessWidget {
  const ReadingHistoryListGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        if (viewportWidth <= 0 || itemCount <= 0) {
          return const SizedBox.shrink();
        }

        final ReadingHistoryListLayoutSpec layout =
            ReadingHistoryListItemMetrics.layoutForViewportWidth(
              viewportWidth,
              horizontalInset: 0,
            );
        return ReadingHistoryVirtualizedRows(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          layout: layout,
        );
      },
    );
  }
}
