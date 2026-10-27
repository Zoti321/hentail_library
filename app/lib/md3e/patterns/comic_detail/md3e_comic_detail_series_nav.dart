import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 系列上一本 / 目录菜单 / 下一本。
class Md3eComicDetailSeriesNav extends StatelessWidget {
  const Md3eComicDetailSeriesNav({
    super.key,
    required this.catalog,
    required this.currentIndex,
    this.onSelectIndex,
    this.onPrev,
    this.onNext,
  });

  final List<String> catalog;
  final int currentIndex;
  final ValueChanged<int>? onSelectIndex;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  bool get _hasPrev => currentIndex > 0;
  bool get _hasNext => currentIndex < catalog.length - 1;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    final List<M3EMenuNode> menuChildren = <M3EMenuNode>[
      for (int i = 0; i < catalog.length; i++)
        M3EMenuSelectable(
          label: catalog[i],
          value: i,
          selected: i == currentIndex,
          onPressed: () => onSelectIndex?.call(i),
        ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Md3eComicDetailSeriesNavIconButton(
          icon: Symbols.chevron_left,
          tooltip: l10n.comicDetailSeriesPrev,
          semanticLabel: l10n.comicDetailSeriesPrevSemantic,
          enabled: _hasPrev,
          onPressed: onPrev,
        ),
        const SizedBox(width: 4),
        Md3eAnchoredMenu(
          position: M3EMenuAnchorPosition.bottomEnd,
          children: menuChildren,
          enabled: catalog.isNotEmpty,
          anchorBuilder: (BuildContext context, VoidCallback open) {
            return _Md3eComicDetailSeriesNavIconButton(
              icon: Symbols.list_alt,
              tooltip: l10n.comicDetailSeriesCatalog,
              semanticLabel: l10n.comicDetailSeriesCatalog,
              enabled: catalog.isNotEmpty,
              onPressed: open,
            );
          },
        ),
        const SizedBox(width: 4),
        _Md3eComicDetailSeriesNavIconButton(
          icon: Symbols.chevron_right,
          tooltip: l10n.comicDetailSeriesNext,
          semanticLabel: l10n.comicDetailSeriesNextSemantic,
          enabled: _hasNext,
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// 禁用时不使用 [M3EIconButton]（避免 null [onPressed] 仍绘制 state layer）。
class _Md3eComicDetailSeriesNavIconButton extends StatelessWidget {
  const _Md3eComicDetailSeriesNavIconButton({
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    required this.enabled,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback? onPressed;

  static const double _hitExtent = 40;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    const double iconSize = Md3eLibraryPageHeaderMetrics.actionIconSize;
    final Color iconColor = enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurface.withValues(alpha: 0.38);

    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: semanticLabel,
        child: SizedBox(
          width: _hitExtent,
          height: _hitExtent,
          child: Center(
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      );
    }

    return M3EIconButton(
      icon: Icon(icon, size: iconSize, color: iconColor),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
    );
  }
}
