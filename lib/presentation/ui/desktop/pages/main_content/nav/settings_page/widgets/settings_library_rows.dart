import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/app_setting.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/foundation/my_toggle_switch.dart';
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
        color: theme.colorScheme.iconDefault,
      ),
      label: '库位置',
      description: '管理扫描路径',
      onRowTap: () => context.push('/paths'),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.iconSecondary,
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
        color: theme.colorScheme.iconDefault,
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

class LibraryHideComicsInSeriesRow extends ConsumerWidget {
  const LibraryHideComicsInSeriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hide = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.libraryHideComicsInSeries ?? false,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      icon: Icon(
        LucideIcons.layers,
        size: 20,
        color: theme.colorScheme.iconDefault,
      ),
      label: '漫画库隐藏系列内漫画',
      description: hide ? '已启用（漫画分区不显示已归入系列的漫画）' : '已禁用（漫画分区显示全部漫画）',
      action: MyToggleSwitch(
        checked: hide,
        onChange: () => ref
            .read(settingsProvider.notifier)
            .setLibraryHideComicsInSeries(!hide),
      ),
    );
  }
}

class HealthyModeRow extends ConsumerWidget {
  const HealthyModeRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool healthy = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.isHealthyMode ?? false,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      icon: healthy
          ? Icon(
              LucideIcons.shield,
              size: 20,
              color: theme.colorScheme.iconDefault,
            )
          : Icon(
              LucideIcons.shieldOff,
              size: 20,
              color: theme.colorScheme.warning,
            ),
      label: '健全模式',
      description: healthy ? '已启用（隐藏 R18）' : '已禁用（显示 R18）',
      action: MyToggleSwitch(
        checked: healthy,
        onChange: () => ref.read(settingsProvider.notifier).toggleHealthyMode(),
      ),
      isDestructive: !healthy,
    );
  }
}
