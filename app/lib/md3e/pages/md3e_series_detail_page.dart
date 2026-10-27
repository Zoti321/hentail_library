import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_series_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_pinned_header_delegate.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_comics_section.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_intro_section.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_page_header.dart';
import 'package:hentai_library/md3e/widgets/navigation/md3e_library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

export 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
export 'package:hentai_library/md3e/pages/md3e_series_detail_page_preview_data.dart';

/// 系列详情页 Lab：粘滞页头 + 可滚动简介与漫画网格。
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
  final GlobalKey _headerMeasureKey = GlobalKey();
  final GlobalKey _comicsSectionKey = GlobalKey();
  double? _headerExtent;
  late int _pageSize = widget.entry.initialPageSize;
  late int _page = widget.entry.initialPage.clamp(
    1,
    _totalPagesFor(widget.entry, widget.entry.initialPageSize),
  );
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  static int _totalPagesFor(Md3eSeriesDetailEntry entry, int pageSize) {
    final int count = entry.comics.length;
    if (count == 0) {
      return 1;
    }
    return (count / pageSize).ceil();
  }

  int get _totalPages => _totalPagesFor(widget.entry, _pageSize);

  List<Md3eSeriesDetailComicItem> get _pageItems {
    final List<Md3eSeriesDetailComicItem> comics = widget.entry.comics;
    if (comics.isEmpty) {
      return const <Md3eSeriesDetailComicItem>[];
    }
    final int start = (_page - 1) * _pageSize;
    if (start >= comics.length) {
      return const <Md3eSeriesDetailComicItem>[];
    }
    final int end = (start + _pageSize).clamp(0, comics.length);
    return comics.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didUpdateWidget(covariant Md3eSeriesDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _pageSize = widget.entry.initialPageSize;
      _page = widget.entry.initialPage.clamp(1, _totalPages);
    }
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
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

  void _scrollToComicsSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? target = _comicsSectionKey.currentContext;
      if (!mounted || target == null) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    });
  }

  void _setPage(int page) {
    setState(() => _page = page.clamp(1, _totalPages));
    _scrollToComicsSection();
  }

  void _setPageSize(int size) {
    setState(() {
      _pageSize = size;
      _page = _page.clamp(1, _totalPages);
    });
    _scrollToComicsSection();
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

    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Md3eSeriesDetailPageHeader(
          onBack: _resolveVoid(widget.onBack),
          onEdit: _resolveVoid(widget.onEdit),
          moreMenuEntries: _resolveMoreMenu(l10n),
          pageSize: _pageSize,
          onPageSizeChanged: _setPageSize,
        ),
      ),
    );

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(scheme),
      child: Stack(
        children: <Widget>[
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              if (_headerExtent == null)
                SliverToBoxAdapter(child: header)
              else
                SliverPersistentHeader(
                  pinned: true,
                  delegate: Md3eLibraryPinnedHeaderDelegate(
                    extent: _headerExtent!,
                    child: header,
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  introTop,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Md3eSeriesDetailIntroSection(
                    entry: widget.entry,
                    onMetadataChipTap: widget.onMetadataChipTap ?? (_) {},
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: Md3eSeriesDetailComicsSection(
                  gridSectionKey: _comicsSectionKey,
                  pageItems: _pageItems,
                  page: _page,
                  totalPages: _totalPages,
                  onPageChanged: _setPage,
                  onComicTap: widget.onComicTap,
                ),
              ),
            ],
          ),
          Md3eLibraryScrollToTopButton(
            scrollController: _scrollController,
            horizontalPadding: horizontalPadding,
          ),
        ],
      ),
    );
  }
}
