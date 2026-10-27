import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_page_size_control.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_detail_header_toolbar.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_pinned_toolbar_chrome.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列详情工具栏内容（粘滞阴影由 [Md3eLibraryPinnedHeaderDelegate] 绘制）。
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

    return Md3ePinnedToolbarChrome(
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
    );
  }
}
