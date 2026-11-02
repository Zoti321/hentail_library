import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_page_header.dart';
import 'package:hentai_library/features/library_browse/presentation/series/patterns/series_detail/series_detail_page_size_control.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_header_toolbar.dart';
import 'package:hentai_library/shared/ui/patterns/shared/pinned_toolbar_chrome.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列详情工具栏内容（粘滞阴影由 [Md3ePageHeaderDelegate] 绘制）。
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
