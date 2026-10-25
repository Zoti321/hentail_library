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
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (var i = 0; i < section.rows.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    title: Text(section.rows[i].title),
                    subtitle: section.rows[i].subtitle == null
                        ? null
                        : Text(section.rows[i].subtitle!),
                    trailing: section.rows[i].trailing,
                    onTap: section.rows[i].onTap,
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
