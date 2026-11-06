import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 页面标题：统一使用 [PageLayoutSpec.titleStyle]，各页面不再自行拼字号/字重。
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: layout.titleStyle(theme.typeScale, theme.colorScheme.onSurface),
    );
  }
}
