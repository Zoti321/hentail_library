import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_series_detail_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_page_size_control.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_detail_header_toolbar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列详情固定顶栏（轻阴影，与生产 [SeriesDetailHeader] 一致）。
class Md3eSeriesDetailPageHeader extends StatelessWidget {
  const Md3eSeriesDetailPageHeader({
    super.key,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries = const <M3EMenuNode>[],
    required this.pageSize,
    required this.onPageSizeChanged,
    this.pageSizeOptions = kMd3eLibraryPageSizeOptions,
  });

  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode> moreMenuEntries;
  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizeOptions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double horizontalInset =
        Md3eSeriesDetailPageMetrics.contentHorizontalPadding(sizeClass);

    return Material(
      color: scheme.surface,
      elevation: M3EElevation.level1,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      surfaceTintColor: const Color(0x00000000),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            top: Md3eSeriesDetailPageMetrics.headerTopPadding(sizeClass),
            bottom: Md3eSeriesDetailPageMetrics.headerBottomPadding(sizeClass),
          ),
          child: SizedBox(
            height: Md3eSeriesDetailPageMetrics.toolbarHeight,
            child: Row(
              children: <Widget>[
                Md3eDetailHeaderToolbar(
                  onBack: onBack,
                  onEdit: onEdit,
                  editTooltip: l10n.seriesDetailEdit,
                  moreMenuEntries: moreMenuEntries,
                ),
                const Spacer(),
                Md3eSeriesDetailPageSizeControl(
                  pageSize: pageSize,
                  onPageSizeChanged: onPageSizeChanged,
                  pageSizeOptions: pageSizeOptions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
