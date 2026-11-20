import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// Generic settings row: show current enum label, open [pickAnchoredOption] on tap.
class SettingsEnumNavigationTile<T extends Enum> extends StatelessWidget {
  const SettingsEnumNavigationTile({
    super.key,
    required this.leading,
    required this.title,
    required this.preference,
    required this.options,
    required this.labelOf,
    required this.onSelected,
    this.description,
    this.enabled = true,
  });

  final IconData leading;
  final Widget title;
  final Widget? description;
  final T preference;
  final List<T> options;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsNavigationTile(
      leading: leading,
      title: title,
      description: description,
      value: Text(labelOf(preference)),
      enabled: enabled,
      onTap: () => pickAnchoredOption<T>(
        context,
        options: options,
        selected: preference,
        labelOf: labelOf,
        onSelected: onSelected,
      ),
    );
  }
}
