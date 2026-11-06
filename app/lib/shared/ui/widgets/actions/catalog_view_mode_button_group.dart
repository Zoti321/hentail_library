import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 与 Kazumi / 书库工具栏一致的 Lucide 图标尺寸（20dp）。
const double kCatalogViewModeButtonGroupIconSize = 20;

/// 漫画库目录展示：竖向标准卡片 vs 横向圆角矩形卡片（同一套元数据，仅容器形态不同）。
enum CatalogViewMode { grid, list }

/// Kazumi / M3E：connected tonal 双图标按钮组（卡片 · 列表）。
///
/// 选中态 `secondaryContainer`、未选 `surfaceContainerLow`（随 [M3EThemeData]）。
class CatalogViewModeButtonGroup extends StatelessWidget {
  const CatalogViewModeButtonGroup({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.size = M3EButtonSize.sm,
  });

  final CatalogViewMode mode;
  final ValueChanged<CatalogViewMode> onModeChanged;
  final M3EButtonSize size;

  static int indexForMode(CatalogViewMode mode) {
    return switch (mode) {
      CatalogViewMode.grid => 0,
      CatalogViewMode.list => 1,
    };
  }

  static CatalogViewMode modeForIndex(int index) {
    return switch (index) {
      0 => CatalogViewMode.grid,
      1 => CatalogViewMode.list,
      _ => CatalogViewMode.grid,
    };
  }

  @override
  Widget build(BuildContext context) {
    return M3EButtonGroup(
      type: M3EButtonGroupType.connected,
      direction: Axis.horizontal,
      shape: M3EButtonShape.round,
      size: size,
      style: M3EButtonStyle.tonal,
      density: M3EButtonGroupDensity.regular,
      neighborSquish: true,
      expandedRatio: 0.15,
      overflow: M3EButtonGroupOverflow.experimentalPaging,
      selectionRequired: true,
      selectedIndex: indexForMode(mode),
      onSelectedIndexChanged: (int? index) {
        if (index == null) {
          return;
        }
        onModeChanged(modeForIndex(index));
      },
      decoration: catalogViewModeButtonGroupDecoration(context),
      actions: const <M3EButtonGroupAction>[
        M3EButtonGroupAction(
          icon: Icon(
            LucideIcons.layoutGrid,
            size: kCatalogViewModeButtonGroupIconSize,
          ),
          semanticLabel: '卡片视图',
          minWidth: 48,
        ),
        M3EButtonGroupAction(
          icon: Icon(
            LucideIcons.list,
            size: kCatalogViewModeButtonGroupIconSize,
          ),
          semanticLabel: '列表视图',
          minWidth: 48,
        ),
      ],
    );
  }
}

/// 选中 / 未选底色（对齐 Kazumi tonal 分段控件观感）。
M3EButtonDecoration catalogViewModeButtonGroupDecoration(BuildContext context) {
  final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
  return M3EButtonDecoration(
    iconSize: kCatalogViewModeButtonGroupIconSize,
    foregroundColor: WidgetStatePropertyAll<Color?>(scheme.onSurfaceVariant),
    backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return scheme.secondaryContainer;
      }
      if (states.contains(WidgetState.disabled)) {
        return scheme.surfaceContainerLow.withValues(alpha: 0.38);
      }
      return scheme.surfaceContainerLow;
    }),
  );
}
