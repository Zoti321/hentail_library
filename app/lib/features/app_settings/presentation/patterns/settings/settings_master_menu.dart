import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
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
    this.masterGroupTitle,
    this.visibleCategories,
  });

  final bool wide;
  final SettingsCategory selected;
  final ValueChanged<SettingsCategory> onSelect;

  /// Shown above rail items on wide layouts (e.g. 「应用」).
  final String? masterGroupTitle;

  /// 为 null 时显示全部分类。
  final Set<SettingsCategory>? visibleCategories;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<SettingsCategoryInfo> categories =
        <SettingsCategoryInfo>[
          for (final SettingsCategoryInfo info in kSettingsCategories)
            if (visibleCategories == null ||
                visibleCategories!.contains(info.category))
              info,
        ];

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
                child: SettingsSectionHeader(
                  title: Text(masterGroupTitle!),
                ),
              ),
            for (final SettingsCategoryInfo info in categories)
              SettingsRailDestination(
                icon: info.icon,
                label: info.label(l10n),
                selected: selected == info.category,
                onTap: () => onSelect(info.category),
              ),
          ] else
            ContentSection.group(
              title: masterGroupTitle ?? l10n.navSettings,
              children: <Widget>[
                for (final SettingsCategoryInfo info in categories)
                  SettingsCategoryTile(
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
