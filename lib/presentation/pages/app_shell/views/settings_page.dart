import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/my_toggle_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (data) => SingleChildScrollView(
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
              ],
            ),

            _SettingsGroup(
              title: '漫画库',
              children: [
                _SettingsRow(
                  icon: Icon(
                    LucideIcons.folderSearch,
                    size: 20,
                    color: theme.colorScheme.iconDefault,
                  ),
                  label: '库位置',
                  description: '管理扫描路径',
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
                  description: '启动时扫描选中路径',
                  action: const MyToggleSwitch(checked: true),
                ),
                _SettingsRow(
                  icon: data.isHealthyMode
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
                  description: data.isHealthyMode
                      ? '已启用（隐藏 R18）'
                      : '已禁用（显示 R18）',
                  action: MyToggleSwitch(
                    checked: data.isHealthyMode,
                    onChange: () =>
                        ref.read(settingsProvider.notifier).toggleHealthyMode(),
                  ),
                  isDestructive: !data.isHealthyMode,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          error.toString(),
          style: TextStyle(color: theme.colorScheme.error),
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
  final bool isDestructive;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.description,
    this.action,
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
