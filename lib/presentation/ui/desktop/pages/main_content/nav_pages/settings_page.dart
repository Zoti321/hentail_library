import 'dart:async';

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/format_byte_size.dart';
import 'package:hentai_library/domain/entity/app_setting.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/foundation/my_toggle_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const int _readerAutoPlayIntervalMin = 1;
const int _readerAutoPlayIntervalMax = 60;
const double _kAppThemeMenuWidth = 224;

enum _SettingsShell { loading, content, fatalError }

_SettingsShell _settingsShell(AsyncValue<AppSetting> value) {
  if (value.hasError && !value.hasValue) {
    return _SettingsShell.fatalError;
  }
  if (!value.hasValue) {
    return _SettingsShell.loading;
  }
  return _SettingsShell.content;
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final _SettingsShell shell = ref.watch(
      settingsProvider.select(_settingsShell),
    );
    return switch (shell) {
      _SettingsShell.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      _SettingsShell.content => const _SettingsLoadedView(),
      _SettingsShell.fatalError => Center(
        child: Text(
          ref.watch(settingsProvider).error.toString(),
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    };
  }
}

class _SettingsLoadedView extends StatelessWidget {
  const _SettingsLoadedView();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '设置',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.textPrimary,
              ),
            ),
          ),
          _SettingsGroup(
            title: '个性化',
            children: const <Widget>[_ThemePreferenceRow()],
          ),
          _SettingsGroup(
            title: '漫画库',
            children: const <Widget>[
              _LibraryLocationRow(),
              _AutoScanRow(),
              _LibraryHideComicsInSeriesRow(),
              _HealthyModeRow(),
            ],
          ),
          _SettingsGroup(
            title: '缓存',
            children: const <Widget>[
              _ArchiveCoverDiskCacheRow(),
              _ArchiveCoverCacheUsageRow(),
            ],
          ),
          _SettingsGroup(
            title: '阅读',
            children: const <Widget>[_ReaderAutoPlayIntervalRow()],
          ),
          _SettingsGroup(
            title: '关于',
            children: const <Widget>[_AboutVersionRow()],
          ),
        ],
      ),
    );
  }
}

class _ThemePreferenceRow extends ConsumerStatefulWidget {
  const _ThemePreferenceRow();

  @override
  ConsumerState<_ThemePreferenceRow> createState() =>
      _ThemePreferenceRowState();
}

class _ThemePreferenceRowState extends ConsumerState<_ThemePreferenceRow> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  Future<void> _applyTheme(AppThemePreference value) async {
    _menuController.hideMenu();
    await ref.read(settingsProvider.notifier).setThemePreference(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppThemePreference? pref = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) => async.asData?.value.themePreference,
      ),
    );
    if (pref == null) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return _SettingsRow(
      icon: Icon(LucideIcons.palette, size: 20, color: cs.iconDefault),
      label: '应用主题',
      description: '可跟随系统或固定浅色、深色；当前：${pref.labelZh}',
      onRowTap: () => _menuController.showMenu(),
      action: CustomPopupMenu(
        controller: _menuController,
        barrierColor: Colors.transparent,
        pressType: PressType.singleClick,
        showArrow: false,
        verticalMargin: -24,
        menuBuilder: () =>
            _AppThemePreferenceMenuPanel(current: pref, onSelect: _applyTheme),
        child: GhostButton.iconText(
          icon: LucideIcons.chevronsUpDown,
          text: pref.labelZh,
          tooltip: '',
          semanticLabel: '选择应用主题',
          iconSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: tokens.radius.md,
          foregroundColor: cs.textSecondary,
          hoverColor: cs.hoverBackground,
          overlayColor: cs.primary.withAlpha(14),
          delayTooltipThreeSeconds: false,
          onPressed: () => _menuController.toggleMenu(),
        ),
      ),
    );
  }
}

class _AppThemePreferenceMenuPanel extends StatelessWidget {
  const _AppThemePreferenceMenuPanel({
    required this.current,
    required this.onSelect,
  });

  final AppThemePreference current;
  final Future<void> Function(AppThemePreference value) onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      width: _kAppThemeMenuWidth,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: cs.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.cardShadowHover,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(bottom: BorderSide(color: cs.borderSubtle)),
              ),
              child: Text(
                '应用主题',
                style: TextStyle(
                  fontSize: tokens.text.bodySm,
                  fontWeight: FontWeight.w600,
                  color: cs.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AppThemePreference.values.map((AppThemePreference p) {
                  final bool isSelected = p == current;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelect(p),
                        borderRadius: BorderRadius.circular(tokens.radius.md),
                        hoverColor: cs.primary.withAlpha(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spacing.sm,
                            vertical: tokens.spacing.sm,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                isSelected
                                    ? LucideIcons.circleCheckBig
                                    : LucideIcons.circle,
                                size: 18,
                                color: isSelected
                                    ? cs.primary
                                    : cs.textTertiary,
                              ),
                              SizedBox(width: tokens.spacing.sm),
                              Expanded(
                                child: Text(
                                  p.labelZh,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: cs.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryLocationRow extends StatelessWidget {
  const _LibraryLocationRow();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _SettingsRow(
      icon: Icon(
        LucideIcons.folderSearch,
        size: 20,
        color: theme.colorScheme.iconDefault,
      ),
      label: '库位置',
      description: '管理扫描路径',
      onRowTap: () => context.go('/paths'),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.iconSecondary,
      ),
    );
  }
}

class _AutoScanRow extends ConsumerWidget {
  const _AutoScanRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool autoScan = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) => async.asData?.value.autoScan ?? false,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return _SettingsRow(
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

class _LibraryHideComicsInSeriesRow extends ConsumerWidget {
  const _LibraryHideComicsInSeriesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hide = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.libraryHideComicsInSeries ?? false,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return _SettingsRow(
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

class _ArchiveCoverDiskCacheRow extends ConsumerWidget {
  const _ArchiveCoverDiskCacheRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.archiveCoverDiskCacheEnabled ?? true,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return _SettingsRow(
      icon: Icon(
        LucideIcons.image,
        size: 20,
        color: theme.colorScheme.iconDefault,
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

class _ArchiveCoverCacheUsageRow extends ConsumerStatefulWidget {
  const _ArchiveCoverCacheUsageRow();

  @override
  ConsumerState<_ArchiveCoverCacheUsageRow> createState() =>
      _ArchiveCoverCacheUsageRowState();
}

class _ArchiveCoverCacheUsageRowState
    extends ConsumerState<_ArchiveCoverCacheUsageRow> {
  bool _isClearing = false;

  Future<void> _clearCache() async {
    if (_isClearing) {
      return;
    }
    setState(() => _isClearing = true);
    try {
      await ref.read(archiveCoverCacheProvider).clearAll();
      ref.invalidate(archiveCoverCacheDiskUsageBytesProvider);
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
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
    return _SettingsRow(
      icon: Icon(
        LucideIcons.hardDrive,
        size: 20,
        color: theme.colorScheme.iconDefault,
      ),
      label: '缓存占用',
      description: description,
      action: GhostButton.iconText(
        icon: LucideIcons.trash2,
        text: _isClearing ? '清理中…' : '清理',
        tooltip: '',
        semanticLabel: '清除封面磁盘缓存',
        onPressed: _isClearing ? null : () => unawaited(_clearCache()),
        iconSize: 15,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: tokens.radius.md,
        foregroundColor: theme.colorScheme.textSecondary,
        hoverColor: theme.colorScheme.hoverBackground,
        overlayColor: theme.colorScheme.primary.withAlpha(14),
        delayTooltipThreeSeconds: false,
      ),
    );
  }
}

class _HealthyModeRow extends ConsumerWidget {
  const _HealthyModeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool healthy = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.isHealthyMode ?? false,
      ),
    );
    final ThemeData theme = Theme.of(context);
    return _SettingsRow(
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

class _ReaderAutoPlayIntervalRow extends ConsumerWidget {
  const _ReaderAutoPlayIntervalRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int seconds = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.readerAutoPlayIntervalSeconds ?? 5,
      ),
    );
    return _SettingsRow(
      icon: Icon(
        LucideIcons.timer,
        size: 20,
        color: Theme.of(context).colorScheme.iconDefault,
      ),
      label: '自动播放间隔',
      description: '$seconds 秒',
      action: _IntervalAdjuster(
        value: seconds,
        min: _readerAutoPlayIntervalMin,
        max: _readerAutoPlayIntervalMax,
        onDecrease: () {
          ref
              .read(settingsProvider.notifier)
              .setReaderAutoPlayIntervalSeconds(seconds - 1);
        },
        onIncrease: () {
          ref
              .read(settingsProvider.notifier)
              .setReaderAutoPlayIntervalSeconds(seconds + 1);
        },
      ),
    );
  }
}

class _AboutVersionRow extends StatelessWidget {
  const _AboutVersionRow();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _SettingsRow(
      icon: Icon(
        LucideIcons.info,
        size: 20,
        color: theme.colorScheme.iconDefault,
      ),
      label: '版本',
      description: 'v1.0.0',
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.inputBackgroundDisabled,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '检查更新',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.textTertiary,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.textTertiary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.cardShadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++)
                  Column(
                    children: [
                      children[i],
                      if (i < children.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.colorScheme.inputBackgroundDisabled,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatefulWidget {
  final Widget icon;
  final String label;
  final String? description;
  final Widget? action;
  final bool isDestructive;
  final VoidCallback? onRowTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.description,
    this.action,
    this.isDestructive = false,
    this.onRowTap,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onRowTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onRowTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).colorScheme.hoverBackground
                : Theme.of(context).colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 20, height: 20, child: widget.icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isDestructive
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.action != null) ...[
                  const SizedBox(width: 16),
                  widget.action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntervalAdjuster extends StatelessWidget {
  const _IntervalAdjuster({
    required this.value,
    required this.min,
    required this.max,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final int min;
  final int max;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool canDecrease = value > min;
    final bool canIncrease = value < max;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.minus,
          size: 24,
          tooltip: '',
          semanticLabel: '减少自动播放间隔',
          onPressed: canDecrease ? onDecrease : null,
          iconSize: 14,
          borderRadius: 8,
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$value s',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GhostButton.icon(
          icon: LucideIcons.plus,
          size: 24,
          tooltip: '',
          semanticLabel: '增加自动播放间隔',
          onPressed: canIncrease ? onIncrease : null,
          iconSize: 14,
          borderRadius: 8,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).colorScheme.borderSubtle
                : Theme.of(context).colorScheme.inputBackgroundDisabled,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeButton extends StatefulWidget {
  final String currentTheme;
  final VoidCallback onToggle;

  const _ThemeButton({required this.currentTheme, required this.onToggle});

  @override
  State<_ThemeButton> createState() => _ThemeButtonState();
}

class _ThemeButtonState extends State<_ThemeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isHovered
                    ? Theme.of(context).colorScheme.borderSubtle
                    : Theme.of(context).colorScheme.inputBackgroundDisabled,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '切换至 ${widget.currentTheme == 'pink' ? 'Fluent' : 'Material'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
