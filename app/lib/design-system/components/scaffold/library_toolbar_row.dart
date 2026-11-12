import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/components/scaffold/library_page_header_metrics.dart';
import 'package:hentai_library/design-system/components/scaffold/page_header_back_button.dart';
import 'package:hentai_library/design-system/layout/page_layout_spec.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 页头工具行：可选返回 + 可选汉堡 + 标题 + 尾部插槽。
///
/// 上下留白与水平留白由外层页头 chrome 提供。
/// 本组件不取业务文案：汉堡的 [menuTooltip] / [menuSemanticLabel] 由调用方注入。
class LibraryToolbarRow extends StatelessWidget {
  const LibraryToolbarRow({
    super.key,
    required this.title,
    this.onBack,
    this.onOpenNavigation,
    this.trailing = const <Widget>[],
    this.showMenu,
    this.menuTooltip,
    this.menuSemanticLabel,
  });

  final Widget title;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNavigation;
  final List<Widget> trailing;

  /// 默认按「紧凑屏宽且存在导航回调」推导。
  final bool? showMenu;
  final String? menuTooltip;
  final String? menuSemanticLabel;

  /// 返回 / 汉堡与标题之间的唯一间距。
  static const double actionGap = 4;

  @override
  Widget build(BuildContext context) {
    final bool resolvedShowMenu =
        showMenu ??
        (PageLayoutSpec.of(context).sizeClass.isCompact &&
            onOpenNavigation != null);
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return SizedBox(
      height: PageLayoutSpec.toolbarRowHeight,
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            PageHeaderBackButton(onPressed: onBack!),
            const SizedBox(width: actionGap),
          ],
          if (resolvedShowMenu) ...<Widget>[
            M3EIconButton(
              icon: Icon(
                Symbols.menu,
                size: LibraryPageHeaderMetrics.actionIconSize,
                color: scheme.onSurfaceVariant,
              ),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: menuTooltip,
              semanticLabel: menuSemanticLabel,
              onPressed: onOpenNavigation,
            ),
            const SizedBox(width: actionGap),
          ],
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: title),
          ),
          ...trailing,
        ],
      ),
    );
  }
}
