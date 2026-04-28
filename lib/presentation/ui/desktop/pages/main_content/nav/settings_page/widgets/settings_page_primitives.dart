import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
            boxShadow: <BoxShadow>[
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
              children: <Widget>[
                for (int i = 0; i < children.length; i++)
                  Column(
                    children: <Widget>[
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

class SettingsRow extends StatefulWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.action,
    this.isDestructive = false,
    this.onRowTap,
  });

  final Widget icon;
  final String label;
  final String? description;
  final Widget? action;
  final bool isDestructive;
  final VoidCallback? onRowTap;

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: widget.onRowTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onRowTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovered
                ? colorScheme.hoverBackground
                : colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                SizedBox(width: 20, height: 20, child: widget.icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isDestructive
                              ? colorScheme.error
                              : colorScheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.description != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.action != null) ...<Widget>[
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

class IntervalAdjuster extends StatelessWidget {
  const IntervalAdjuster({
    super.key,
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
