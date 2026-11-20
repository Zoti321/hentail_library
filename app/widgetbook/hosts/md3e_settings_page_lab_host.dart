import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/presentation/lab/lab_settings_provider_overrides.dart';
import 'package:hentai_library/features/app_settings/presentation/lab/lab_settings_sections.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page_body.dart';

/// Lab / Widgetbook：生产 sections + in-memory [settingsProvider]；阅读 / 元数据备份仍为 mock。
class SettingsPageLabHost extends StatefulWidget {
  const SettingsPageLabHost({
    super.key,
    this.initialCategory = SettingsCategory.appearance,
    this.initialLabState = const SettingsLabState(),
    this.onBack,
  });

  final SettingsCategory initialCategory;
  final SettingsLabState initialLabState;
  final VoidCallback? onBack;

  @override
  State<SettingsPageLabHost> createState() => _Md3eSettingsPageLabHostState();
}

class _Md3eSettingsPageLabHostState extends State<SettingsPageLabHost> {
  late SettingsLabState _labState = widget.initialLabState;

  void _onLabStateChanged(SettingsLabState next) {
    setState(() => _labState = next);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: labSettingsProviderOverrides(),
      child: SettingsLayout(
        initialCategory: widget.initialCategory,
        labState: _labState,
        onLabStateChanged: _onLabStateChanged,
        onBack: widget.onBack,
        sectionsBuilder: (BuildContext context, SettingsCategory category) {
          return labSettingsSectionsFor(
            context,
            category,
            labState: _labState,
            onLabStateChanged: _onLabStateChanged,
          );
        },
      ),
    );
  }
}
