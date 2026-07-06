import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/my_toggle_switch.dart';
import 'package:hentai_library/ui/features/settings/state/app_update_controller.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AutoUpdateRow extends ConsumerWidget {
  const AutoUpdateRow({super.key});

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
      icon: Icon(
        LucideIcons.download,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '自动更新',
      description: autoUpdate ? '已启用（启动时检查更新）' : '已禁用',
      action: MyToggleSwitch(
        checked: autoUpdate,
        onChange: () =>
            ref.read(settingsProvider.notifier).setAutoUpdate(!autoUpdate),
      ),
    );
  }
}

class AboutVersionRow extends ConsumerWidget {
  const AboutVersionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PackageInfo> packageInfoAsync = ref.watch(
      packageInfoProvider,
    );
    final ThemeData theme = Theme.of(context);
    final String versionLabel = packageInfoAsync.maybeWhen(
      data: (PackageInfo info) => 'v${info.version}',
      orElse: () => '加载中…',
    );
    return SettingsRow(
      icon: Icon(
        LucideIcons.info,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '版本',
      description: versionLabel,
      onRowTap: packageInfoAsync.isLoading
          ? null
          : () => ref
                .read(appUpdateControllerProvider.notifier)
                .runManualCheck(context: context),
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.hentai.inputBackgroundDisabled,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '检查更新',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.hentai.textTertiary,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
