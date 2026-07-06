import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/core/widgets/foundation/my_toggle_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LibraryLocationRow extends StatelessWidget {
  const LibraryLocationRow({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      icon: Icon(
        LucideIcons.folderSearch,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '库位置',
      description: '管理扫描路径',
      onRowTap: () => context.push('/paths'),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}

class AutoScanRow extends ConsumerWidget {
  const AutoScanRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool autoScan = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) => async.asData?.value.autoScan ?? false,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      icon: Icon(
        LucideIcons.refreshCw,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '自动扫描',
      description: autoScan ? '已启用（启动时扫描选中路径）' : '已禁用',
      action: MyToggleSwitch(
        checked: autoScan,
        onChange: () =>
            ref.read(settingsProvider.notifier).setAutoScan(!autoScan),
      ),
    );
  }
}
