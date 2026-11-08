import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_series_catalog_sheet.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 系列上一本 / 目录菜单 / 下一本。
///
/// medium-（&lt; [Breakpoints.expanded]）仅保留「系列目录」图标，点击打开 bottom sheet。
class ComicDetailSeriesNav extends StatelessWidget {
  const ComicDetailSeriesNav({
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

  void _openCatalogSheet(BuildContext context) {
    ComicDetailSeriesCatalogSheet.show(
      context,
      catalog: catalog,
      currentIndex: currentIndex,
      onSelectIndex: (int index) => onSelectIndex?.call(index),
    );
  }

  Widget _catalogButton(BuildContext context, {required VoidCallback? onPressed}) {
    final AppLocalizations l10n = context.l10n;
    return _ComicDetailSeriesNavIconButton(
      icon: Symbols.list_alt,
      tooltip: l10n.comicDetailSeriesCatalog,
      semanticLabel: l10n.comicDetailSeriesCatalog,
      enabled: catalog.isNotEmpty && onPressed != null,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool useSheet =
        MediaQuery.sizeOf(context).width < Breakpoints.expanded;

    if (useSheet) {
      return _catalogButton(
        context,
        onPressed: catalog.isEmpty ? null : () => _openCatalogSheet(context),
      );
    }

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
        _ComicDetailSeriesNavIconButton(
          icon: Symbols.chevron_left,
          tooltip: l10n.comicDetailSeriesPrev,
          semanticLabel: l10n.comicDetailSeriesPrevSemantic,
          enabled: _hasPrev,
          onPressed: onPrev,
        ),
        const SizedBox(width: 4),
        AnchoredMenu(
          position: M3EMenuAnchorPosition.bottomEnd,
          children: menuChildren,
          enabled: catalog.isNotEmpty,
          anchorBuilder: (BuildContext context, VoidCallback open) {
            return _catalogButton(context, onPressed: open);
          },
        ),
        const SizedBox(width: 4),
        _ComicDetailSeriesNavIconButton(
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

/// 禁用时不使用可点的 [M3EIconButton]（避免 null [onPressed] 仍绘制 state layer）。
///
/// 启用/禁用必须占同一槽位：sm 默认 [inflateHitTarget] 会把命中区撑到 48，
/// 而禁用态若只用 40 的 [SizedBox] 会在首/尾卷切换时抖动。
class _ComicDetailSeriesNavIconButton extends StatelessWidget {
  const _ComicDetailSeriesNavIconButton({
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

  /// 与 [M3EIconButtonSize.sm] visual 一致；关闭 inflate 以免与禁用槽错位。
  static const double _slotExtent = 40;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    const double iconSize = LibraryPageHeaderMetrics.actionIconSize;
    final Color iconColor = enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurface.withValues(alpha: 0.38);

    return SizedBox(
      width: _slotExtent,
      height: _slotExtent,
      child: enabled
          ? M3EIconButton(
              icon: Icon(icon, size: iconSize, color: iconColor),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: tooltip,
              semanticLabel: semanticLabel,
              inflateHitTarget: false,
              onPressed: onPressed,
            )
          : Semantics(
              button: true,
              enabled: false,
              label: semanticLabel,
              child: Center(
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
            ),
    );
  }
}
