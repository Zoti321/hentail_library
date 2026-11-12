import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_series_nav.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_header_toolbar.dart';
import 'package:hentai_library/design-system/components/scaffold/pinned_toolbar_chrome.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画详情工具栏：左返回；右为编辑 / 系列目录 / 更多。
class ComicDetailPageHeader extends StatelessWidget {
  const ComicDetailPageHeader({
    super.key,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries = const <M3EMenuNode>[],
    this.seriesCatalog = const <String>[],
    this.seriesCurrentIndex = 0,
    this.showSeriesNav = false,
    this.onSeriesSelectIndex,
  });

  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode> moreMenuEntries;
  final List<String> seriesCatalog;
  final int seriesCurrentIndex;
  final bool showSeriesNav;
  final ValueChanged<int>? onSeriesSelectIndex;

  @override
  Widget build(BuildContext context) {
    final bool showNav = showSeriesNav && seriesCatalog.length > 1;

    return PinnedToolbarChrome(
      child: Row(
        children: <Widget>[
          DetailHeaderBackButton(onBack: onBack),
          const Spacer(),
          DetailHeaderEditButton(
            onEdit: onEdit,
            tooltip: context.l10n.comicDetailEditMetadata,
          ),
          if (showNav)
            ComicDetailSeriesNav(
              catalog: seriesCatalog,
              currentIndex: seriesCurrentIndex.clamp(
                0,
                seriesCatalog.length - 1,
              ),
              onSelectIndex: onSeriesSelectIndex,
            ),
          DetailHeaderMoreButton(moreMenuEntries: moreMenuEntries),
        ],
      ),
    );
  }
}
