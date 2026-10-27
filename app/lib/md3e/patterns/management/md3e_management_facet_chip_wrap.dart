import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/md3e_comic_detail_meta_chip_row.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页当前维度条目：流式 [M3EChip]（suggestion）。
class Md3eManagementFacetChipWrap extends StatelessWidget {
  const Md3eManagementFacetChipWrap({
    super.key,
    required this.labels,
    this.onLabelPressed,
    this.trailing,
  });

  final List<String> labels;
  final ValueChanged<String>? onLabelPressed;

  /// 桌面端：chip 流末尾的内联新建字段等。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty && trailing == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: kMd3eComicDetailMetaChipGap,
      runSpacing: kMd3eComicDetailMetaChipGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final String label in labels)
          M3EChip(
            label: label,
            type: M3EChipType.suggestion,
            // [M3EChip] 在 onPressed 为 null 时走禁用绘制；浏览/预览无回调也需保持启用外观。
            onPressed: () => onLabelPressed?.call(label),
          ),
        ?trailing,
      ],
    );
  }
}
