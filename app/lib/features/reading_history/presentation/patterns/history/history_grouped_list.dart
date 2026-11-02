import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_time_grouping.dart';
import 'package:hentai_library/shared/ui/layout/reading_history_list_layout.dart';
import 'package:hentai_library/shared/ui/motion/spring_value.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 四档时间分组 + 可折叠组标题（sliver）+ 组内懒加载列表。
class Md3eReadingHistoryGroupedList<T> extends StatefulWidget {
  const Md3eReadingHistoryGroupedList({
    super.key,
    required this.groups,
    required this.itemBuilder,
  });

  final List<Md3eHistoryTimeGroup<T>> groups;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<Md3eReadingHistoryGroupedList<T>> createState() =>
      _Md3eReadingHistoryGroupedListState<T>();
}

class _Md3eReadingHistoryGroupedListState<T>
    extends State<Md3eReadingHistoryGroupedList<T>> {
  final Set<Md3eHistoryTimeSection> _collapsed = <Md3eHistoryTimeSection>{};

  bool _isExpanded(Md3eHistoryTimeSection section) {
    return !_collapsed.contains(section);
  }

  void _toggle(Md3eHistoryTimeSection section) {
    setState(() {
      if (_collapsed.contains(section)) {
        _collapsed.remove(section);
      } else {
        _collapsed.add(section);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return SliverMainAxisGroup(
      slivers: <Widget>[
        for (int index = 0; index < widget.groups.length; index++) ...<Widget>[
          if (index > 0)
            SliverToBoxAdapter(child: SizedBox(height: spacing.md)),
          _HistoryGroupSection<T>(
            group: widget.groups[index],
            expanded: _isExpanded(widget.groups[index].section),
            onHeaderPressed: () => _toggle(widget.groups[index].section),
            itemBuilder: widget.itemBuilder,
          ),
        ],
      ],
    );
  }
}

class _HistoryGroupSection<T> extends StatelessWidget {
  const _HistoryGroupSection({
    required this.group,
    required this.expanded,
    required this.onHeaderPressed,
    required this.itemBuilder,
  });

  final Md3eHistoryTimeGroup<T> group;
  final bool expanded;
  final VoidCallback onHeaderPressed;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _HistorySectionHeader(
            section: group.section,
            itemCount: group.items.length,
            expanded: expanded,
            onPressed: onHeaderPressed,
          ),
        ),
        if (expanded) ...<Widget>[
          SliverToBoxAdapter(child: SizedBox(height: spacing.xs)),
          Md3eReadingHistoryListLayout(
            itemCount: group.items.length,
            itemBuilder: (BuildContext context, int index) {
              return itemBuilder(context, group.items[index]);
            },
          ),
        ],
      ],
    );
  }
}

class _HistorySectionHeader extends StatelessWidget {
  const _HistorySectionHeader({
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
                Md3eSpringValue(
                  value: expanded ? 0.5 : 0,
                  builder: (BuildContext context, double turns, Widget? child) {
                    return Transform.rotate(
                      angle: turns * 2 * math.pi,
                      child: child,
                    );
                  },
                  child: Icon(Symbols.expand_more, size: 24, color: foreground),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
