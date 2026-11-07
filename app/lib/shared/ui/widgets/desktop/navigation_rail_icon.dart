import 'package:flutter/widgets.dart';

/// Material Symbols（及同类可变字体）是否支持通过 [Icon.fill] 切换描边/填充。
bool iconSupportsFillVariation(IconData icon) {
  if (icon.fontPackage == 'material_symbols_icons') {
    return true;
  }
  final String? family = icon.fontFamily;
  return family != null && family.startsWith('MaterialSymbols');
}

/// ExpressiveNavigationRail / list-detail rail 图标：选中时尽量使用 filled（fill=1），不支持则保持 [icon]。
Widget navigationRailIconWidget({
  required IconData icon,
  IconData? selectedIcon,
  required bool selected,
  double? size,
  Color? color,
}) {
  final IconData resolvedSelected = selectedIcon ?? icon;
  final bool explicitSelectedPair =
      selectedIcon != null && selectedIcon != icon;

  if (selected) {
    if (explicitSelectedPair) {
      return Icon(resolvedSelected, size: size, color: color);
    }
    if (iconSupportsFillVariation(icon)) {
      return Icon(icon, size: size, color: color, fill: 1);
    }
    return Icon(icon, size: size, color: color);
  }

  if (explicitSelectedPair) {
    return Icon(icon, size: size, color: color);
  }
  if (iconSupportsFillVariation(icon)) {
    return Icon(icon, size: size, color: color, fill: 0);
  }
  return Icon(icon, size: size, color: color);
}
