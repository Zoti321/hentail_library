import 'package:flutter/material.dart';

class ContextMenuActionItem extends StatelessWidget {
  const ContextMenuActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color hoverColor = isDestructive
        ? cs.error.withAlpha(26)
        : cs.primary.withAlpha(10);
    final Color iconColor = enabled
        ? (isDestructive ? cs.error : cs.onSurfaceVariant)
        : cs.onSurfaceVariant;
    final Color labelColor = enabled
        ? (isDestructive ? cs.error : cs.onSurface)
        : cs.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        hoverColor: hoverColor,
        splashColor: hoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
