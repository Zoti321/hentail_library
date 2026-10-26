import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 与 Kazumi / 书库工具栏一致的 Lucide 图标尺寸（20dp）。
const double kMd3eCatalogViewModeButtonGroupIconSize = 20;

/// 漫画库目录展示：封面网格 vs 列表行（Lab 枚举，不绑生产 provider）。
enum Md3eCatalogViewMode {
  grid,
  list,
}

/// Kazumi / M3E：connected tonal 双图标按钮组（卡片 · 列表）。
///
/// 选中态 `secondaryContainer`、未选 `surfaceContainerLow`（随 [M3EThemeData]）。
class Md3eCatalogViewModeButtonGroup extends StatelessWidget {
  const Md3eCatalogViewModeButtonGroup({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.size = M3EButtonSize.sm,
  });

  final Md3eCatalogViewMode mode;
  final ValueChanged<Md3eCatalogViewMode> onModeChanged;
  final M3EButtonSize size;

  static int indexForMode(Md3eCatalogViewMode mode) {
    return switch (mode) {
      Md3eCatalogViewMode.grid => 0,
      Md3eCatalogViewMode.list => 1,
    };
  }

  static Md3eCatalogViewMode modeForIndex(int index) {
    return switch (index) {
      0 => Md3eCatalogViewMode.grid,
      1 => Md3eCatalogViewMode.list,
      _ => Md3eCatalogViewMode.grid,
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
      decoration: md3eCatalogViewModeButtonGroupDecoration(context),
      actions: const <M3EButtonGroupAction>[
        M3EButtonGroupAction(
          icon: Icon(
            LucideIcons.layoutGrid,
            size: kMd3eCatalogViewModeButtonGroupIconSize,
          ),
          semanticLabel: '卡片视图',
          minWidth: 48,
        ),
        M3EButtonGroupAction(
          icon: Icon(
            LucideIcons.list,
            size: kMd3eCatalogViewModeButtonGroupIconSize,
          ),
          semanticLabel: '列表视图',
          minWidth: 48,
        ),
      ],
    );
  }
}

/// 选中 / 未选底色（对齐 Kazumi tonal 分段控件观感）。
M3EButtonDecoration md3eCatalogViewModeButtonGroupDecoration(
  BuildContext context,
) {
  final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
  return M3EButtonDecoration(
    iconSize: kMd3eCatalogViewModeButtonGroupIconSize,
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
