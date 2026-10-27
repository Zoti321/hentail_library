import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_content_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_section_header.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';

/// Settings master pane: rail (wide) or grouped category tiles (narrow).
class Md3eSettingsMasterMenu extends StatelessWidget {
  const Md3eSettingsMasterMenu({
    super.key,
    required this.wide,
    required this.selected,
    required this.onSelect,
    this.masterGroupTitle,
  });

  final bool wide;
  final Md3eSettingsCategory selected;
  final ValueChanged<Md3eSettingsCategory> onSelect;

  /// Shown above rail items on wide layouts (e.g. 「应用」).
  final String? masterGroupTitle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: wide
            ? const EdgeInsets.fromLTRB(4, 0, 0, 12)
            : const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: <Widget>[
          if (wide) ...<Widget>[
            if (masterGroupTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                child: Md3eSettingsSectionHeader(title: Text(masterGroupTitle!)),
              ),
            for (final Md3eSettingsCategoryInfo info in kMd3eSettingsCategories)
              Md3eSettingsRailDestination(
                icon: info.icon,
                label: info.label(l10n),
                selected: selected == info.category,
                onTap: () => onSelect(info.category),
              ),
          ] else
            Md3eContentSection.group(
              title: masterGroupTitle ?? l10n.navSettings,
              children: <Widget>[
                for (final Md3eSettingsCategoryInfo info in kMd3eSettingsCategories)
                  Md3eSettingsCategoryTile(
                    icon: info.icon,
                    title: info.label(l10n),
                    description: info.description(l10n),
                    onTap: () => onSelect(info.category),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
