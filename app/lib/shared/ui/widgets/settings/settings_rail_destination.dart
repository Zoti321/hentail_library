import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// Wide list–detail rail capsule item（视觉由 [ListDetailNavItem] 统一提供）。
class SettingsRailDestination extends StatelessWidget {
  const SettingsRailDestination({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListDetailNavItem(
        icon: icon,
        label: label,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
