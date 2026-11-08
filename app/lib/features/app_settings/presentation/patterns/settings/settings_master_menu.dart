import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_section_header.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';

/// Settings master pane: rail (wide) or grouped category tiles (narrow).
class SettingsMasterMenu extends StatelessWidget {
  const SettingsMasterMenu({
    super.key,
    required this.wide,
    required this.selected,
    required this.onSelect,
    this.visibleCategories,
  });

  final bool wide;
  final SettingsCategory selected;
  final ValueChanged<SettingsCategory> onSelect;

  /// 为 null 时显示全部分类。
  final Set<SettingsCategory>? visibleCategories;

  List<({SettingsMasterGroupInfo group, List<SettingsCategoryInfo> items})>
  _visibleGroups() {
    return <
          ({SettingsMasterGroupInfo group, List<SettingsCategoryInfo> items})
        >[
          for (final SettingsMasterGroupInfo group in kSettingsMasterGroups)
            (
              group: group,
              items: <SettingsCategoryInfo>[
                for (final SettingsCategory category in group.categories)
                  if (visibleCategories == null ||
                      visibleCategories!.contains(category))
                    settingsCategoryInfo(category),
              ],
            ),
        ]
        .where((entry) => entry.items.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final groups = _visibleGroups();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: wide
            ? const EdgeInsets.fromLTRB(4, 0, 0, 12)
            : const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: <Widget>[
          if (wide)
            for (final entry in groups) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                child: SettingsSectionHeader(
                  title: Text(entry.group.label(l10n)),
                ),
              ),
              for (final SettingsCategoryInfo info in entry.items)
                SettingsRailDestination(
                  icon: info.icon,
                  label: info.label(l10n),
                  selected: selected == info.category,
                  onTap: () => onSelect(info.category),
                ),
            ]
          else
            for (int i = 0; i < groups.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: Spacing.space16),
              ContentSection.group(
                title: groups[i].group.label(l10n),
                children: <Widget>[
                  for (final SettingsCategoryInfo info in groups[i].items)
                    SettingsCategoryTile(
                      icon: info.icon,
                      title: info.label(l10n),
                      description: info.description(l10n),
                      onTap: () => onSelect(info.category),
                    ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}
