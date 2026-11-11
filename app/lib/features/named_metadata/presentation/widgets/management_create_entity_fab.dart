import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/managed_named_facet_kind.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页右下角新建 FAB（移动端打开 Dialog，桌面端由 [onPressed] 触发内联字段）。
class ManagementCreateEntityFab extends StatelessWidget {
  const ManagementCreateEntityFab({
    super.key,
    required this.facet,
    required this.horizontalPadding,
    required this.onPressed,
    this.hidden = false,
  });

  final ManagedNamedFacetKind facet;
  final double horizontalPadding;
  final VoidCallback onPressed;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double width = MediaQuery.sizeOf(context).width;
    final WindowSizeClass sizeClass = WindowSizeClass.fromWidth(width);
    final M3EFabSize fabSize = FabSizing.responsive(sizeClass);
    final M3EFabMetrics metrics = theme.fabTheme.resolve(
      size: fabSize,
      color: M3EFabColor.primary,
      scheme: theme.colorScheme,
      enabled: true,
    );

    return Positioned(
      right: horizontalPadding,
      bottom: LibraryBrowsePageMetrics.scrollToTopBottomInset,
      child: Semantics(
        button: true,
        label: l10n.metadataAddLabel(facet),
        child: M3EFab(
          size: fabSize,
          color: M3EFabColor.primary,
          cornerRadius: LibraryBrowsePageMetrics.scrollToTopCornerRadius,
          icon: Icon(Icons.add, size: metrics.iconSize),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
