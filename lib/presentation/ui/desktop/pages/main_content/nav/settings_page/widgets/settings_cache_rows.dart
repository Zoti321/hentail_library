import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/core/util/format_byte_size.dart';
import 'package:hentai_library/model/app_setting.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/foundation/my_toggle_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ArchiveCoverDiskCacheRow extends ConsumerWidget {
  const ArchiveCoverDiskCacheRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.archiveCoverDiskCacheEnabled ?? true,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      icon: Icon(
        LucideIcons.image,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '封面磁盘缓存',
      description: enabled
          ? '已启用(epub/zip/cbz等资源漫画封面写入应用缓存，减轻重复解压)'
          : '已禁用(每次列表展示时重新解码，不读不写缓存文件)',
      action: MyToggleSwitch(
        checked: enabled,
        onChange: () => ref
            .read(settingsProvider.notifier)
            .setArchiveCoverDiskCacheEnabled(!enabled),
      ),
    );
  }
}

class ArchiveCoverCacheUsageRow extends ConsumerStatefulWidget {
  const ArchiveCoverCacheUsageRow({super.key});

  @override
  ConsumerState<ArchiveCoverCacheUsageRow> createState() =>
      _ArchiveCoverCacheUsageRowState();
}

class _ArchiveCoverCacheUsageRowState
    extends ConsumerState<ArchiveCoverCacheUsageRow> {
  bool isClearing = false;

  Future<void> clearCache() async {
    if (isClearing) {
      return;
    }
    setState(() => isClearing = true);
    try {
      await ref.read(archiveCoverCacheProvider).clearAll();
      ref.invalidate(archiveCoverCacheDiskUsageBytesProvider);
    } finally {
      if (mounted) {
        setState(() => isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<int> usage = ref.watch(
      archiveCoverCacheDiskUsageBytesProvider,
    );
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final String description = usage.when(
      data: (int bytes) => '应用缓存目录内封面图片；当前占用 ${formatByteSizeBin1024(bytes)}',
      loading: () => '应用缓存目录内封面图片；正在计算占用…',
      error: (Object _, StackTrace _) => '应用缓存目录内封面图片；无法读取占用',
    );
    return SettingsRow(
      icon: Icon(
        LucideIcons.hardDrive,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '缓存占用',
      description: description,
      action: GhostButton.iconText(
        icon: LucideIcons.trash2,
        text: isClearing ? '清理中…' : '清理',
        tooltip: '',
        semanticLabel: '清除封面磁盘缓存',
        onPressed: isClearing ? null : () => unawaited(clearCache()),
        iconSize: 15,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: tokens.radius.md,
        foregroundColor: theme.colorScheme.hentai.textSecondary,
        hoverColor: theme.colorScheme.hentai.hoverBackground,
        overlayColor: theme.colorScheme.primary.withAlpha(14),
        delayTooltipThreeSeconds: false,
      ),
    );
  }
}
