import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePageShortcutEntries extends StatelessWidget {
  const HomePageShortcutEntries({super.key, required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '快捷入口',
          style: TextStyle(
            fontSize: tokens.text.titleSm,
            fontWeight: FontWeight.w600,
            color: colorScheme.textPrimary,
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        Wrap(
          spacing: tokens.spacing.md,
          runSpacing: tokens.spacing.md,
          children: <Widget>[
            _ShortcutTile(
              icon: LucideIcons.library,
              label: '漫画库',
              onTap: () => context.go('/local'),
              colorScheme: colorScheme,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.history,
              label: '阅读历史',
              onTap: () => context.go('/history'),
              colorScheme: colorScheme,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.layers,
              label: '资料管理',
              onTap: () => context.go('/metadata?tab=tags'),
              colorScheme: colorScheme,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.folderTree,
              label: '选中路径',
              onTap: () => context.go('/paths'),
              colorScheme: colorScheme,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.scanSearch,
              label: '扫描漫画库',
              onTap: onScan,
              colorScheme: colorScheme,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.settings,
              label: '设置',
              onTap: () => context.go('/settings'),
              colorScheme: colorScheme,
              tokens: tokens,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatefulWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;

  @override
  State<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends State<_ShortcutTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = widget.colorScheme;
    final AppThemeTokens tokens = widget.tokens;
    const Duration duration = Duration(milliseconds: 180);
    final Curve curve = Curves.easeOutCubic;
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: colorScheme.primary.withAlpha(20),
          splashColor: colorScheme.primary.withAlpha(28),
          highlightColor: colorScheme.primary.withAlpha(12),
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            width: 120,
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.sm + 2,
              tokens.spacing.md + 2,
              tokens.spacing.sm + 2,
              tokens.spacing.md,
            ),
            decoration: BoxDecoration(
              color: isHovered
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHovered
                    ? colorScheme.primary.withAlpha(100)
                    : colorScheme.borderSubtle,
                width: 1,
              ),
              boxShadow: isHovered
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.shadow.withAlpha(40),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedContainer(
                  duration: duration,
                  curve: curve,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(isHovered ? 26 : 16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(isHovered ? 55 : 35),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: tokens.spacing.sm + 2),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
