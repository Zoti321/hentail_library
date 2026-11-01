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
