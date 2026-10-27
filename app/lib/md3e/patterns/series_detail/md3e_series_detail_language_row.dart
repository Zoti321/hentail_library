import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列摘要语言分段（`|` 分隔，Lab 展示用）。
class Md3eSeriesDetailLanguageRow extends StatelessWidget {
  const Md3eSeriesDetailLanguageRow({super.key, required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle style = theme.typeScale.bodySmall.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final TextStyle separatorStyle = style.copyWith(
      color: theme.colorScheme.outline,
    );

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < languages.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('|', style: separatorStyle),
        ));
      }
      children.add(Text(languages[i], style: style));
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
