import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile_label.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile_shell.dart';

/// Switch row inside a split list.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.leading,
    this.description,
    this.enabled = true,
  });

  final Widget title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? leading;
  final Widget? description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsTileShell(
      enabled: enabled,
      onTap: enabled ? () => onChanged(!value) : null,
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
          const SizedBox(width: 12),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
