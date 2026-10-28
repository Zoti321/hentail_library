import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_metadata_field_lock_button.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
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

/// 字段锁总览：split list（行间距 4dp）；宽屏双列，列间留 gap、无分隔线。
class Md3eMetadataFieldLocksKvList extends StatelessWidget {
  const Md3eMetadataFieldLocksKvList({super.key, required this.entries});

  final List<Md3eMetadataFieldLockKvEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns =
            constraints.maxWidth >= Md3eBreakpoints.medium &&
            entries.length > 1;

        if (!twoColumns) {
          return _Md3eMetadataFieldLocksKvSplitGroup(entries: entries);
        }

        final int split = (entries.length + 1) ~/ 2;
        final double gap = M3ETheme.of(context).spacing.md;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _Md3eMetadataFieldLocksKvSplitGroup(
                entries: entries.sublist(0, split),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _Md3eMetadataFieldLocksKvSplitGroup(
                entries: entries.sublist(split),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Md3eMetadataFieldLocksKvSplitGroup extends StatelessWidget {
  const _Md3eMetadataFieldLocksKvSplitGroup({required this.entries});

  final List<Md3eMetadataFieldLockKvEntry> entries;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle labelStyle = theme.typeScale.bodyLarge.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return Md3eSplitListGroup(
      children: entries
          .map(
            (Md3eMetadataFieldLockKvEntry entry) => Md3eSettingsTileShell(
              onTap: () => entry.onChanged(!entry.locked),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(entry.label, style: labelStyle)),
                  Md3eMetadataFieldLockButton(
                    locked: entry.locked,
                    onChanged: entry.onChanged,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
