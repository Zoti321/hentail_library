import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_header_icon_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 详情顶栏编辑按钮。
class DetailHeaderEditButton extends StatelessWidget {
  const DetailHeaderEditButton({super.key, this.onEdit, required this.tooltip});

  final VoidCallback? onEdit;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return DetailHeaderIconButton(
      icon: Symbols.edit,
      tooltip: tooltip,
      semanticLabel: tooltip,
      onPressed: onEdit,
      iconColor: scheme.onSurfaceVariant,
    );
  }
}
