import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_page_size_control.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_header_toolbar.dart';
import 'package:hentai_library/shared/ui/patterns/shared/pinned_toolbar_chrome.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列详情工具栏：左返回；右为每页数量 / 编辑 / 更多。
class SeriesDetailPageHeader extends StatelessWidget {
  const SeriesDetailPageHeader({
    super.key,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries = const <M3EMenuNode>[],
    required this.pageSize,
    required this.onPageSizeChanged,
    this.pageSizeOptions = kLibraryPageSizeOptions,
  });

  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode> moreMenuEntries;
  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizeOptions;

  @override
  Widget build(BuildContext context) {
    return PinnedToolbarChrome(
      child: Row(
        children: <Widget>[
          DetailHeaderBackButton(onBack: onBack),
          const Spacer(),
          SeriesDetailPageSizeControl(
            pageSize: pageSize,
            onPageSizeChanged: onPageSizeChanged,
            pageSizeOptions: pageSizeOptions,
          ),
          DetailHeaderEditButton(
            onEdit: onEdit,
            tooltip: context.l10n.seriesDetailEdit,
          ),
          DetailHeaderMoreButton(moreMenuEntries: moreMenuEntries),
        ],
      ),
    );
  }
}
