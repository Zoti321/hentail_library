import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/my_toggle_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final settingsAsync = ref.watch(settingsProvider);

    final cacheSizeAsync = ref.watch(comicCacheSizeProvider);

    return settingsAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (data) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
          child: Column(
            crossAxisAlignment: .start,
            spacing: 24,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12),
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
                children: [
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.paintBucket,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '主题风格',
                    description: 'Fluent 蓝',
                    action: _ThemeButton(
                      currentTheme: 'fluent',
                      onToggle: () {},
                    ),
                  ),
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.moon,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '深色模式',
                    description: data.isDarkMode ? '已启用' : '已禁用',
                    action: MyToggleSwitch(
                      checked: data.isDarkMode,
                      onChange: () {
                        ref.read(settingsProvider.notifier).toggleDarkMode();
                      },
                    ),
                  ),
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.palette,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '应用主题',
                    description: '跟随系统',
                    action: Row(
                      children: [
                        Text(
                          '浅色',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: theme.colorScheme.iconSecondary,
                        ),
                      ],
                    ),
                  ),
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.layoutTemplate,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '布局密度',
                    description: '紧凑',
                    action: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.colorScheme.iconSecondary,
                    ),
                  ),
                ],
              ),

              _SettingsGroup(
                title: '书库',
                children: [
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.folderSearch,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '库位置',
                    description: '管理扫描文件夹',
                    action: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.colorScheme.iconSecondary,
                    ),
                  ),
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.refreshCw,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '自动扫描',
                    description: '启动时扫描新章节',
                    action: const MyToggleSwitch(checked: true),
                  ),
                  _SettingsRow(
                    icon: data.isR18Mode
                        ? Icon(
                            LucideIcons.shieldAlert,
                            size: 20,
                            color: Colors.red.shade500,
                          )
                        : Icon(
                            LucideIcons.lock,
                            size: 20,
                            color: theme.colorScheme.iconDefault,
                          ),
                    label: 'R18 内容',
                    description: data.isR18Mode ? '显示成人内容' : '隐藏成人内容',
                    action: MyToggleSwitch(
                      checked: data.isR18Mode,
                      onChange: () =>
                          ref.read(settingsProvider.notifier).toggleR18Mode(),
                    ),
                    isDestructive: data.isR18Mode,
                  ),
                ],
              ),

              _SettingsGroup(
                title: '存储',
                children: [
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.database,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '缓存',
                    description: cacheSizeAsync.when(
                      data: (data) => '已用 ${data.toReadableSize()}',
                      error: (error, stackTrace) => "加载失败",
                      loading: () => "加载中",
                    ),
                    action: _ActionButton(
                      label: '清理',
                      onTap: () {
                        ref.read(comicFileCacheServiceProvider).clearAllCache();
                        ref.invalidate(comicFileCacheServiceProvider);
                      },
                    ),
                  ),
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '清理',
                    description: '移除已删除文件的缩略图',
                    action: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.colorScheme.iconSecondary,
                    ),
                    onClick: () {},
                  ),
                ],
              ),

              _SettingsGroup(
                title: '关于',
                children: [
                  _SettingsRow(
                    icon: Icon(
                      LucideIcons.info,
                      size: 20,
                      color: theme.colorScheme.iconDefault,
                    ),
                    label: '版本',
                    description: 'v2.1.0 (动态主题)',
                    action: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          error.toString(),
          style: const TextStyle(color: Colors.red),
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
      crossAxisAlignment: .start,
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
  final VoidCallback? onClick;
  final bool isDestructive;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.description,
    this.action,
    this.onClick,
    this.isDestructive = false,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onClick,
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
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isDestructive
                              ? Colors.red.shade600
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
