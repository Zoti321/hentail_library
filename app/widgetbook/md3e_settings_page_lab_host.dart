import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_settings_page.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';

/// Lab / Widgetbook：设置页 preview 状态由 Host 持有（阅读偏好、Healthy mode 等 tile 仅内存，不写 AppSetting）。
class Md3eSettingsPageLabHost extends StatefulWidget {
  const Md3eSettingsPageLabHost({
    super.key,
    this.initialCategory = Md3eSettingsCategory.personalization,
    this.masterGroupTitle = '应用',
    this.initialLabState = const Md3eSettingsLabState(),
    this.onBack,
  });

  final Md3eSettingsCategory initialCategory;
  final String? masterGroupTitle;
  final Md3eSettingsLabState initialLabState;
  final VoidCallback? onBack;

  @override
  State<Md3eSettingsPageLabHost> createState() =>
      _Md3eSettingsPageLabHostState();
}

class _Md3eSettingsPageLabHostState extends State<Md3eSettingsPageLabHost> {
  late Md3eSettingsLabState _labState = widget.initialLabState;

  void _onLabStateChanged(Md3eSettingsLabState next) {
    setState(() => _labState = next);
  }

  @override
  Widget build(BuildContext context) {
    return Md3eSettingsPage(
      initialCategory: widget.initialCategory,
      masterGroupTitle: widget.masterGroupTitle,
      labState: _labState,
      onLabStateChanged: _onLabStateChanged,
      onBack: widget.onBack,
    );
  }
}
