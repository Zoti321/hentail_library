import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Label column width on comic detail metadata rows (production `kComicDetailMetaLabelWidth`).
const double kComicDetailMetaLabelWidth = 88;

/// Horizontal gap between metadata chips (MASTER §5.1).
const double kComicDetailMetaChipGap = 8;

/// One KV row: fixed-width label + wrapping suggestion chips (detail tag / author / …).
class ComicDetailMetaChipRow<T> extends StatelessWidget {
  const ComicDetailMetaChipRow({
    super.key,
    required this.label,
    required this.items,
    this.labelOf,
    this.onItemTap,
  });

  final String label;
  final List<T> items;

  /// chip 文案；缺省取 `toString()`（`String` 项即为自身）。
  final String Function(T item)? labelOf;
  final ValueChanged<T>? onItemTap;

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
          width: kComicDetailMetaLabelWidth,
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
            spacing: kComicDetailMetaChipGap,
            runSpacing: kComicDetailMetaChipGap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final T item in items)
                M3EChip(
                  label: labelOf?.call(item) ?? '$item',
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
