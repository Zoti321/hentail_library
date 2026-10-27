import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_time_section.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读历史分组标题：左侧 `{分桶} • {数量}`，右侧展开/折叠图标。
class Md3eHistorySectionHeader extends StatelessWidget {
  const Md3eHistorySectionHeader({
    super.key,
    required this.section,
    required this.itemCount,
    required this.expanded,
    required this.onPressed,
  });

  final Md3eHistoryTimeSection section;
  final int itemCount;
  final bool expanded;
  final VoidCallback onPressed;

  static const String _separator = ' • ';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);

    final String bucketLabel = md3eHistoryTimeSectionLabel(l10n, section);
    final String countLabel = l10n.historySectionItemCount(itemCount);
    final String titleText = '$bucketLabel$_separator$countLabel';

    return Semantics(
      button: true,
      expanded: expanded,
      label: '$bucketLabel，$countLabel',
      child: M3ETappable(
        onTap: onPressed,
        trackHover: true,
        semanticLabel: null,
        builder: (BuildContext context, M3EInteractionState state) {
          final Color foreground = scheme.onSurfaceVariant;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: Md3eMotion.motionDurationOf(
                    context,
                    Md3eMotion.durationShort,
                  ),
                  curve: Md3eMotion.curveForStateEnter(
                    reduceMotion: reduceMotion,
                  ),
                  child: Icon(
                    Symbols.expand_more,
                    size: 24,
                    color: foreground,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
