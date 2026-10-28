import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Group label above settings blocks (primary [titleSmall]).
class Md3eSettingsSectionHeader extends StatelessWidget {
  const Md3eSettingsSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  final Widget title;
  final Widget? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETypeScale type = theme.typeScale;
    final M3EColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: DefaultTextStyle.merge(
                  style: type.titleSmall.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  child: title,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (description != null) ...<Widget>[
          SizedBox(height: theme.spacing.xs),
          DefaultTextStyle.merge(
            style: type.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
            child: description!,
          ),
        ],
      ],
    );
  }
}
