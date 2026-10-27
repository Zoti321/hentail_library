import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_header_toolbar.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_series_nav.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_pinned_toolbar_chrome.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画详情工具栏内容（粘滞阴影由 [Md3eLibraryPinnedHeaderDelegate] 绘制）。
class Md3eComicDetailPageHeader extends StatelessWidget {
  const Md3eComicDetailPageHeader({
    super.key,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries = const <M3EMenuNode>[],
    this.seriesCatalog = const <String>[],
    this.seriesCurrentIndex = 0,
    this.showSeriesNav = false,
    this.onSeriesSelectIndex,
    this.onSeriesPrev,
    this.onSeriesNext,
  });

  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode> moreMenuEntries;
  final List<String> seriesCatalog;
  final int seriesCurrentIndex;
  final bool showSeriesNav;
  final ValueChanged<int>? onSeriesSelectIndex;
  final VoidCallback? onSeriesPrev;
  final VoidCallback? onSeriesNext;

  @override
  Widget build(BuildContext context) {
    final bool showNav = showSeriesNav && seriesCatalog.length > 1;

    return Md3ePinnedToolbarChrome(
      child: Row(
        children: <Widget>[
          Md3eComicDetailHeaderToolbar(
            onBack: onBack,
            onEdit: onEdit,
            moreMenuEntries: moreMenuEntries,
          ),
          const Spacer(),
          if (showNav)
            Md3eComicDetailSeriesNav(
              catalog: seriesCatalog,
              currentIndex: seriesCurrentIndex.clamp(
                0,
                seriesCatalog.length - 1,
              ),
              onSelectIndex: onSeriesSelectIndex,
              onPrev: onSeriesPrev,
              onNext: onSeriesNext,
            ),
        ],
      ),
    );
  }
}
