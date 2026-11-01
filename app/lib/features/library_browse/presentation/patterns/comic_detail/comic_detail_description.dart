import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 简介纯文本，默认最多 4 行截断。
class Md3eComicDetailDescription extends StatelessWidget {
  const Md3eComicDetailDescription({
    super.key,
    required this.text,
    this.maxLines = 4,
  });

  final String? text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final String? trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const SizedBox.shrink();
    }
    final M3EThemeData theme = M3ETheme.of(context);
    return Text(
      trimmed,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.typeScale.bodySmall.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }
}
