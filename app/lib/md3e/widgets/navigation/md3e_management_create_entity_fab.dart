import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_named_facet.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页右下角新建 FAB（移动端打开 Dialog，桌面端由 [onPressed] 触发内联字段）。
class Md3eManagementCreateEntityFab extends StatelessWidget {
  const Md3eManagementCreateEntityFab({
    super.key,
    required this.facet,
    required this.horizontalPadding,
    required this.onPressed,
    this.hidden = false,
  });

  final Md3eManagementNamedFacet facet;
  final double horizontalPadding;
  final VoidCallback onPressed;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return const SizedBox.shrink();
    }

    final M3EThemeData theme = M3ETheme.of(context);
    final double width = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(width);
    final M3EFabSize fabSize =
        Md3eLibraryBrowsePageMetrics.scrollToTopFabSize(sizeClass);
    final M3EFabMetrics metrics = theme.fabTheme.resolve(
      size: fabSize,
      color: M3EFabColor.primary,
      scheme: theme.colorScheme,
      enabled: true,
    );

    return Positioned(
      right: horizontalPadding,
      bottom: Md3eLibraryBrowsePageMetrics.scrollToTopBottomInset,
      child: Semantics(
        button: true,
        label: facet.createDialogTitle,
        child: M3EFab(
          size: fabSize,
          color: M3EFabColor.primary,
          cornerRadius: Md3eLibraryBrowsePageMetrics.scrollToTopCornerRadius,
          icon: Icon(
            Icons.add,
            size: metrics.iconSize,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
