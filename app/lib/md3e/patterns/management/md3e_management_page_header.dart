import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 管理页粘滞头：仅左侧标题（与 [Md3eLibraryPageHeader] 同款间距与字阶）。
class Md3eManagementPageHeader extends StatelessWidget {
  const Md3eManagementPageHeader({super.key, this.title = '管理'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(windowWidth);
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    return Padding(
      padding: const EdgeInsets.only(
        top: Md3eLibraryPageHeaderMetrics.verticalPadding,
        bottom: Md3eLibraryPageHeaderMetrics.browsePinnedHeaderBottomPadding,
      ),
      child: SizedBox(
        height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: type.headlineSmall.copyWith(
              fontSize: Md3eLibraryPageHeaderMetrics.titleFontSize(sizeClass),
              fontWeight: Md3eLibraryPageHeaderMetrics.titleFontWeight(sizeClass),
              color: scheme.onSurface,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ),
    );
  }
}
