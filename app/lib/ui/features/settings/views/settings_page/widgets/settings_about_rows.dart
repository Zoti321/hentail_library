import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/features/settings/state/app_update_controller.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AutoUpdateRow extends ConsumerWidget {
  const AutoUpdateRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool autoUpdate = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.autoUpdate ?? true,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.download,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '自动更新',
      action: ToggleSwitch(
        checked: autoUpdate,
        onChange: () =>
            ref.read(settingsProvider.notifier).setAutoUpdate(!autoUpdate),
      ),
    );
  }
}

class AboutVersionRow extends ConsumerWidget {
  const AboutVersionRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PackageInfo> packageInfoAsync = ref.watch(
      packageInfoProvider,
    );
    final ThemeData theme = Theme.of(context);
    final String versionActionLabel = packageInfoAsync.maybeWhen(
      data: (PackageInfo info) => '当前版本 v${info.version}',
      orElse: () => '当前版本 …',
    );
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.info,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '检查更新',
      onRowTap: packageInfoAsync.isLoading
          ? null
          : () => ref
                .read(appUpdateControllerProvider.notifier)
                .runManualCheck(context: context),
      action: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          versionActionLabel,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.hentai.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      ),
    );
  }
}
