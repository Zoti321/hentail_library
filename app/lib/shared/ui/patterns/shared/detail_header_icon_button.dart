import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/components/scaffold/library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 详情顶栏共用图标按钮。
class DetailHeaderIconButton extends StatelessWidget {
  const DetailHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    required this.onPressed,
    required this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    const double iconSize = LibraryPageHeaderMetrics.actionIconSize;
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
