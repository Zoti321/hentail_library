import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Label column width on comic detail metadata rows (production `kComicDetailMetaLabelWidth`).
const double kMd3eComicDetailMetaLabelWidth = 88;

/// Horizontal gap between metadata chips (MASTER §5.1).
const double kMd3eComicDetailMetaChipGap = 8;

/// One KV row: fixed-width label + wrapping suggestion chips (detail tag / author / …).
class Md3eComicDetailMetaChipRow extends StatelessWidget {
  const Md3eComicDetailMetaChipRow({
    super.key,
    required this.label,
    required this.items,
    this.onItemTap,
  });

  final String label;
  final List<String> items;
  final ValueChanged<String>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: kMd3eComicDetailMetaLabelWidth,
          child: Text(
            label,
            style: type.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        SizedBox(width: theme.spacing.lg),
        Expanded(
          child: Wrap(
            spacing: kMd3eComicDetailMetaChipGap,
            runSpacing: kMd3eComicDetailMetaChipGap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final String item in items)
                M3EChip(
                  label: item,
                  type: M3EChipType.suggestion,
                  onPressed: () => onItemTap?.call(item),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Comic detail metadata block preview: tag row(s) with KV layout (Widgetbook / lab).
class Md3eComicDetailMetadataTagsSection extends StatelessWidget {
  const Md3eComicDetailMetadataTagsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.md,
        children: <Widget>[
          const Md3eComicDetailMetaChipRow(
            label: '作者',
            items: <String>['示例作者甲', '示例作者乙'],
          ),
          const Md3eComicDetailMetaChipRow(
            label: '角色',
            items: <String>['角色 A', '角色 B', '角色 C'],
          ),
          const Md3eComicDetailMetaChipRow(
            label: '标签',
            items: <String>[
              '深海',
              '图书馆',
              '奇幻',
              '长篇',
              '连载中',
            ],
          ),
        ],
      ),
    );
  }
}
