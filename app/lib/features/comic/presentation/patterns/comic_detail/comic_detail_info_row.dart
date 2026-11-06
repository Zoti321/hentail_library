import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/comic_detail/comic_detail_meta_chip_row.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// KV 行：固定宽 label + 值（资源格式 / 路径等）。
class ComicDetailInfoRow extends StatelessWidget {
  const ComicDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.tooltip,
  });

  final String label;
  final String value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETypeScale type = theme.typeScale;
    final M3EColorScheme scheme = theme.colorScheme;

    final Widget valueWidget = Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: type.bodySmall.copyWith(color: scheme.onSurfaceVariant),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: tooltip == null
              ? valueWidget
              : Tooltip(message: tooltip, child: valueWidget),
        ),
      ],
    );
  }
}
