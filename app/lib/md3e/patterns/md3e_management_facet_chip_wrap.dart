import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/md3e_comic_detail_meta_chip_row.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页当前维度条目：流式 [M3EChip]（suggestion）。
class Md3eManagementFacetChipWrap extends StatelessWidget {
  const Md3eManagementFacetChipWrap({
    super.key,
    required this.labels,
    this.onLabelPressed,
  });

  final List<String> labels;
  final ValueChanged<String>? onLabelPressed;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
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
            onPressed: onLabelPressed == null
                ? null
                : () => onLabelPressed!(label),
          ),
      ],
    );
  }
}
