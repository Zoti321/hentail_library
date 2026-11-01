import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// list-detail 左侧导航项（胶囊形），与设置页宽屏 rail 同款视觉。
///
/// - 选中：`secondaryContainer` 底色 + `onSecondaryContainer` 文字/图标。
/// - 未选中：透明底 + `onSurfaceVariant` 文字/图标。
/// - hover / press / focus 仅由 [InkWell] 的水波纹状态层呈现；无阴影、无 elevation，
///   也不依赖有内部状态的按钮组件，避免切换选中后残留 hover 底色。
class Md3eListDetailNavItem extends StatelessWidget {
  const Md3eListDetailNavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final M3ETypeScale type = M3ETheme.of(context).typeScale;
    final Color foreground = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 16),
              if (icon != null) ...<Widget>[
                Icon(icon, size: 24, color: foreground),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: type.labelLarge.copyWith(color: foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
