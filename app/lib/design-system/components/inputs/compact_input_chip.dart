import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/components/inputs/input_chip_field_layout.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class CompactInputChip extends StatelessWidget {
  const CompactInputChip({
    super.key,
    required this.label,
    required this.onPressed,
    required this.onDeleted,
  });

  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return M3ETheme(
      data: theme.copyWith(chipTheme: compactInputChipTheme(theme.chipTheme)),
      child: M3EChip(
        label: inputChipDisplayLabel(label),
        type: M3EChipType.input,
        onPressed: onPressed,
        onDeleted: onDeleted,
      ),
    );
  }
}
