import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/metadata_field_lock_button.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/ui/widgets/settings/split_list_group.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 单条字段锁 KV 行（左字段名、右锁按钮）。
class MetadataFieldLockKvEntry {
  const MetadataFieldLockKvEntry({
    required this.label,
    required this.locked,
    required this.onChanged,
  });

  final String label;
  final bool locked;
  final ValueChanged<bool> onChanged;
}

/// 字段锁总览：split list（行间距 4dp）；宽屏双列，列间留 gap、无分隔线。
class MetadataFieldLocksKvList extends StatelessWidget {
  const MetadataFieldLocksKvList({super.key, required this.entries});

  final List<MetadataFieldLockKvEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns =
            constraints.maxWidth >= Breakpoints.medium && entries.length > 1;

        if (!twoColumns) {
          return _MetadataFieldLocksKvSplitGroup(entries: entries);
        }

        final int split = (entries.length + 1) ~/ 2;
        final double gap = M3ETheme.of(context).spacing.md;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _MetadataFieldLocksKvSplitGroup(
                entries: entries.sublist(0, split),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _MetadataFieldLocksKvSplitGroup(
                entries: entries.sublist(split),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetadataFieldLocksKvSplitGroup extends StatelessWidget {
  const _MetadataFieldLocksKvSplitGroup({required this.entries});

  final List<MetadataFieldLockKvEntry> entries;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle labelStyle = theme.typeScale.bodyLarge.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return SplitListGroup(
      children: entries
          .map(
            (MetadataFieldLockKvEntry entry) => SettingsTileShell(
              onTap: () => entry.onChanged(!entry.locked),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(entry.label, style: labelStyle)),
                  MetadataFieldLockButton(
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
