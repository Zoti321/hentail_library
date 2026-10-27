import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_series_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_comics_section.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_intro_section.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

export 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
export 'package:hentai_library/md3e/pages/md3e_series_detail_page_preview_data.dart';

/// 系列详情页 Lab：固定顶栏 + 可滚动简介与漫画网格。
class Md3eSeriesDetailPage extends StatefulWidget {
  const Md3eSeriesDetailPage({
    super.key,
    required this.entry,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries,
    this.onMetadataChipTap,
    this.onComicTap,
    this.scrollController,
  });

  final Md3eSeriesDetailEntry entry;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode>? moreMenuEntries;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<int>? onComicTap;
  final ScrollController? scrollController;

  @override
  State<Md3eSeriesDetailPage> createState() => _Md3eSeriesDetailPageState();
}

class _Md3eSeriesDetailPageState extends State<Md3eSeriesDetailPage> {
  late Md3eSeriesDetailEntry _entry = widget.entry;
  late int _pageSize = widget.entry.initialPageSize;
  late int _page = widget.entry.initialPage.clamp(1, _totalPages);
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  int get _totalPages {
    final int count = _entry.comics.length;
    if (count == 0) {
      return 1;
    }
    return (count / _pageSize).ceil();
  }

  List<Md3eSeriesDetailComicItem> get _pageItems {
    if (_entry.comics.isEmpty) {
      return const <Md3eSeriesDetailComicItem>[];
    }
    final int start = (_page - 1) * _pageSize;
    if (start >= _entry.comics.length) {
      return const <Md3eSeriesDetailComicItem>[];
    }
    final int end = (start + _pageSize).clamp(0, _entry.comics.length);
    return _entry.comics.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant Md3eSeriesDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _entry = widget.entry;
      _pageSize = widget.entry.initialPageSize;
      _page = widget.entry.initialPage.clamp(1, _totalPages);
    }
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  VoidCallback _resolveVoid(VoidCallback? handler) => handler ?? () {};

  List<M3EMenuNode> _resolveMoreMenu(AppLocalizations l10n) {
    if (widget.moreMenuEntries != null) {
      return widget.moreMenuEntries!;
    }
    return <M3EMenuNode>[
      M3EMenuEntry(
        label: l10n.refreshMetadata,
        leading: const Icon(Symbols.refresh),
        onPressed: () {},
      ),
      M3EMenuEntry(
        label: l10n.catalogSelectionEnter,
        leading: const Icon(Symbols.check_box),
        onPressed: () {},
      ),
      M3EMenuEntry(
        label: l10n.comicDetailShowInExplorer,
        leading: const Icon(Symbols.folder_open),
        onPressed: () {},
      ),
    ];
  }

  void _setPage(int page) {
    setState(() => _page = page.clamp(1, _totalPages));
  }

  void _setPageSize(int size) {
    setState(() {
      _pageSize = size;
      _page = _page.clamp(1, _totalPages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double horizontalPadding =
        Md3eSeriesDetailPageMetrics.contentHorizontalPadding(sizeClass);
    final double introTop =
        Md3eSeriesDetailPageMetrics.introTopSpacing(sizeClass);

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Md3eSeriesDetailPageHeader(
            onBack: _resolveVoid(widget.onBack),
            onEdit: _resolveVoid(widget.onEdit),
            moreMenuEntries: _resolveMoreMenu(l10n),
            pageSize: _pageSize,
            onPageSizeChanged: _setPageSize,
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    introTop,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Md3eSeriesDetailIntroSection(
                      entry: _entry,
                      onMetadataChipTap:
                          widget.onMetadataChipTap ?? (_) {},
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: Md3eSeriesDetailComicsSection(
                    pageItems: _pageItems,
                    page: _page,
                    totalPages: _totalPages,
                    onPageChanged: _setPage,
                    onComicTap: widget.onComicTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
