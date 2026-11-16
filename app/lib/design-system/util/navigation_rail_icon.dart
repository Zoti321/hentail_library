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
class NavigationRailIcon extends StatelessWidget {
  const NavigationRailIcon({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.selected,
    this.size,
    this.color,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final bool selected;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
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
}
