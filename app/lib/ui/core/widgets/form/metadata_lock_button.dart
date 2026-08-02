import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Komga 式字段锁开关：锁定时用主题强调色（对应 Komga 橙色锁）。
class MetadataLockButton extends StatelessWidget {
  const MetadataLockButton({
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color color = !enabled
        ? cs.hentai.textTertiary
        : locked
        ? cs.primary
        : cs.hentai.textTertiary;
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      onPressed: enabled ? () => onChanged(!locked) : null,
      icon: Icon(
        locked ? LucideIcons.lock : LucideIcons.lockOpen,
        size: 16,
        color: color,
      ),
    );
  }
}
