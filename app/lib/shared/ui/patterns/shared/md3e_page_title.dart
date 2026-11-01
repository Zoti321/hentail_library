import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 页面标题：统一使用 [Md3ePageLayoutSpec.titleStyle]，各页面不再自行拼字号/字重。
class Md3ePageTitle extends StatelessWidget {
  const Md3ePageTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: layout.titleStyle(theme.typeScale, theme.colorScheme.onSurface),
    );
  }
}
