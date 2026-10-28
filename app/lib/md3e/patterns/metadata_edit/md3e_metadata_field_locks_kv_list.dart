import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_metadata_field_lock_button.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 单条字段锁 KV 行（左字段名、右锁按钮）。
class Md3eMetadataFieldLockKvEntry {
  const Md3eMetadataFieldLockKvEntry({
    required this.label,
    required this.locked,
    required this.onChanged,
  });

  final String label;
  final bool locked;
  final ValueChanged<bool> onChanged;
}

/// 字段锁总览：单一 tonal 卡片 + 行分隔；宽屏双列。与编辑壳断点无关，行背景一致。
class Md3eMetadataFieldLocksKvList extends StatelessWidget {
  const Md3eMetadataFieldLocksKvList({super.key, required this.entries});

  final List<Md3eMetadataFieldLockKvEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Md3eTonalSurface(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool twoColumns =
              constraints.maxWidth >= Md3eBreakpoints.medium &&
              entries.length > 1;

          if (!twoColumns) {
            return _Md3eMetadataFieldLocksKvColumn(entries: entries);
          }

          final int split = (entries.length + 1) ~/ 2;
          final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _Md3eMetadataFieldLocksKvColumn(
                    entries: entries.sublist(0, split),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: _Md3eMetadataFieldLocksKvColumn(
                    entries: entries.sublist(split),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Md3eMetadataFieldLocksKvColumn extends StatelessWidget {
  const _Md3eMetadataFieldLocksKvColumn({required this.entries});

  final List<Md3eMetadataFieldLockKvEntry> entries;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle labelStyle = theme.typeScale.bodyLarge.copyWith(
      color: scheme.onSurface,
    );
    final Color dividerColor = scheme.outlineVariant.withValues(alpha: 0.35);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < entries.length; i++) ...<Widget>[
          if (i > 0)
            Divider(height: 1, thickness: 1, color: dividerColor),
          Md3eSettingsTileShell(
            onTap: () => entries[i].onChanged(!entries[i].locked),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(entries[i].label, style: labelStyle),
                ),
                Md3eMetadataFieldLockButton(
                  locked: entries[i].locked,
                  onChanged: entries[i].onChanged,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
