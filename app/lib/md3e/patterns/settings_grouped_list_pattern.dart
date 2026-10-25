import 'package:flutter/material.dart';
import 'package:material_expressive/theme.dart';

/// A single row in [Md3eSettingsGroupedListPattern].
class Md3eSettingsRow {
  const Md3eSettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

/// Settings-style grouped list (scene pattern; props only, no feature imports).
class Md3eSettingsGroupedListPattern extends StatelessWidget {
  const Md3eSettingsGroupedListPattern({
    super.key,
    required this.sections,
  });

  final List<({String header, List<Md3eSettingsRow> rows})> sections;

  @override
  Widget build(BuildContext context) {
    final ExpressiveThemeData tokens = ExpressiveThemeProvider.of(context);
    final ThemeData theme = Theme.of(context);
    final double groupRadius = tokens.radius.lg;
    return ListView(
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: <Widget>[
        for (final ({String header, List<Md3eSettingsRow> rows}) section
            in sections) ...<Widget>[
          Padding(
            padding: EdgeInsets.only(
              left: tokens.spacing.sm,
              bottom: tokens.spacing.sm,
            ),
            child: Text(
              section.header,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(groupRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < section.rows.length; i++) ...<Widget>[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  _Md3eSettingsGroupRow(
                    row: section.rows[i],
                    horizontalPadding: tokens.spacing.lg,
                    verticalPadding: tokens.spacing.md,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.lg),
        ],
      ],
    );
  }
}

class _Md3eSettingsGroupRow extends StatelessWidget {
  const _Md3eSettingsGroupRow({
    required this.row,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final Md3eSettingsRow row;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(row.title, style: textTheme.titleMedium),
                if (row.subtitle != null) ...<Widget>[
                  SizedBox(height: 2),
                  Text(
                    row.subtitle!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (row.trailing != null) ...<Widget>[
            SizedBox(width: horizontalPadding),
            row.trailing!,
          ],
        ],
      ),
    );

    if (row.onTap == null) {
      return content;
    }
    return InkWell(onTap: row.onTap, child: content);
  }
}
