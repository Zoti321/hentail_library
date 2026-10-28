import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 表单项标题行（label + 右侧附件，如字段锁）。
class Md3eMetadataFieldLabelRow extends StatelessWidget {
  const Md3eMetadataFieldLabelRow({
    super.key,
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle style = theme.typeScale.labelLarge.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
