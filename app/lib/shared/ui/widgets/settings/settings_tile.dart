import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_nav_item.dart';
import 'package:hentai_library/shared/ui/widgets/settings/split_list_group.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

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
            child: _SettingsTileLabel(
              title: title,
              leading: leading,
              description: description,
              enabled: enabled,
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: 12),
            DefaultTextStyle.merge(
              style: M3ETheme.of(context).typeScale.bodyMedium
                  .copyWith(color: _secondaryColor(context, enabled)),
              child: value!,
            ),
          ],
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            IconTheme.merge(
              data: IconThemeData(color: _secondaryColor(context, enabled)),
              child: trailing!,
            ),
          ] else if (onTap != null) ...<Widget>[
            const SizedBox(width: 8),
            Icon(
              Symbols.chevron_right,
              color: _secondaryColor(context, enabled),
            ),
          ],
        ],
      ),
    );
  }
}

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
            child: _SettingsTileLabel(
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

/// Wide master list category row (icon + title + description + chevron).
class SettingsCategoryTile extends StatelessWidget {
  const SettingsCategoryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    return InkWell(
      onTap: onTap,
      onHighlightChanged: SplitListRow.pressReporterOf(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: type.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: type.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

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

class SettingsTileShell extends StatelessWidget {
  const SettingsTileShell({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onHighlightChanged: SplitListRow.pressReporterOf(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsTileLabel extends StatelessWidget {
  const _SettingsTileLabel({
    required this.title,
    this.leading,
    this.description,
    required this.enabled,
  });

  final Widget title;
  final IconData? leading;
  final Widget? description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final M3ETypeScale type = M3ETheme.of(context).typeScale;
    final Color foreground = enabled
        ? M3ETheme.of(context).colorScheme.onSurface
        : _disabledOn(context);
    final Color secondary = _secondaryColor(context, enabled);

    return Row(
      children: <Widget>[
        if (leading != null) ...<Widget>[
          Icon(leading, size: 24, color: secondary),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DefaultTextStyle.merge(
                style: type.bodyLarge.copyWith(color: foreground),
                child: title,
              ),
              if (description != null) ...<Widget>[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: type.bodySmall.copyWith(color: secondary),
                  child: description!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Color _disabledOn(BuildContext context) {
  return M3ETheme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
}

Color _secondaryColor(BuildContext context, bool enabled) {
  final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
  return enabled ? scheme.onSurfaceVariant : _disabledOn(context);
}
