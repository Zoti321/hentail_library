import 'package:flutter/material.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page_body.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';

/// Lab / Widgetbook：设置页 preview 状态由 Host 持有（阅读偏好、Healthy mode 等 tile 仅内存，不写 AppSetting）。
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
  State<SettingsPageLabHost> createState() =>
      _Md3eSettingsPageLabHostState();
}

class _Md3eSettingsPageLabHostState extends State<SettingsPageLabHost> {
  late SettingsLabState _labState = widget.initialLabState;

  void _onLabStateChanged(SettingsLabState next) {
    setState(() => _labState = next);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsLayout(
      initialCategory: widget.initialCategory,
      labState: _labState,
      onLabStateChanged: _onLabStateChanged,
      onBack: widget.onBack,
    );
  }
}
