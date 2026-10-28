import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Komga 式元数据字段锁（Lab / M3E 主题；对齐生产 [MetadataLockButton] 语义）。
class Md3eMetadataFieldLockButton extends StatelessWidget {
  const Md3eMetadataFieldLockButton({
    super.key,
    required this.locked,
    required this.onChanged,
    this.enabled = true,
  });

  final bool locked;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color iconColor = !enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
        : locked
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    return M3EIconButton(
      icon: Icon(
        locked ? Symbols.lock : Symbols.lock_open_right,
        size: 18,
        color: iconColor,
      ),
      variant: locked
          ? M3EIconButtonVariant.tonal
          : M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: locked ? '字段已锁定' : '锁定字段',
      semanticLabel: locked ? '字段已锁定' : '锁定字段',
      onPressed: enabled ? () => onChanged(!locked) : null,
    );
  }
}
