import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile_label.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile_shell.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

export 'package:hentai_library/shared/ui/widgets/settings/settings_category_tile.dart';
export 'package:hentai_library/shared/ui/widgets/settings/settings_rail_destination.dart';
export 'package:hentai_library/shared/ui/widgets/settings/settings_switch_tile.dart';
export 'package:hentai_library/shared/ui/widgets/settings/settings_tile_label.dart';
export 'package:hentai_library/shared/ui/widgets/settings/settings_tile_shell.dart';

/// Navigation row inside a split list (title + optional description + chevron).
class SettingsNavigationTile extends StatelessWidget {
  const SettingsNavigationTile({
    super.key,
    required this.title,
    this.leading,
    this.description,
    this.trailing,
    this.value,
    this.onTap,
    this.enabled = true,
  });

  final Widget title;
  final IconData? leading;
  final Widget? description;
  final Widget? trailing;
  final Widget? value;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsTileShell(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: SettingsTileLabel(
              title: title,
              leading: leading,
              description: description,
              enabled: enabled,
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: 12),
            DefaultTextStyle.merge(
              style: M3ETheme.of(context).typeScale.bodyMedium.copyWith(
                color: settingsTileSecondaryColor(context, enabled),
              ),
              child: value!,
            ),
          ],
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            IconTheme.merge(
              data: IconThemeData(
                color: settingsTileSecondaryColor(context, enabled),
              ),
              child: trailing!,
            ),
          ] else if (onTap != null) ...<Widget>[
            const SizedBox(width: 8),
            Icon(
              Symbols.chevron_right,
              color: settingsTileSecondaryColor(context, enabled),
            ),
          ],
        ],
      ),
    );
  }
}
