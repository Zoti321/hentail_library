import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Color settingsTileDisabledOn(BuildContext context) {
  return M3ETheme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
}

Color settingsTileSecondaryColor(BuildContext context, bool enabled) {
  final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
  return enabled ? scheme.onSurfaceVariant : settingsTileDisabledOn(context);
}

class SettingsTileLabel extends StatelessWidget {
  const SettingsTileLabel({
    super.key,
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
        : settingsTileDisabledOn(context);
    final Color secondary = settingsTileSecondaryColor(context, enabled);

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
