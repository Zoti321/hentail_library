import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_section_header.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Scrollable detail column with optional max width (Kazumi-style ~1000dp).
class Md3eSettingsList extends StatelessWidget {
  const Md3eSettingsList({
    super.key,
    required this.sections,
    this.maxWidth = 1000,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final List<Widget> sections;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: sections.length,
      itemBuilder: (BuildContext context, int index) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: sections[index],
          ),
        );
      },
    );
  }
}

/// One titled group of [Md3eSplitListGroup] tiles in a settings detail pane.
class Md3eSettingsSection extends StatelessWidget {
  const Md3eSettingsSection({
    super.key,
    required this.tiles,
    this.title,
    this.bottomInfo,
    this.margin,
  });

  final List<Widget> tiles;
  final Widget? title;
  final Widget? bottomInfo;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Md3eSettingsSectionHeader(title: title!),
            ),
          Md3eSplitListGroup(children: tiles),
          if (bottomInfo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DefaultTextStyle.merge(
                style: theme.typeScale.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: bottomInfo!,
              ),
            ),
        ],
      ),
    );
  }
}
