import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_page_header.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_scroll_content.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_pinned_header_delegate.dart';
import 'package:hentai_library/md3e/widgets/navigation/md3e_library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

export 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
export 'package:hentai_library/md3e/pages/md3e_comic_detail_page_preview_data.dart';

/// 漫画详情页 Lab：粘滞页头 + 可滚动正文。
class Md3eComicDetailPage extends StatefulWidget {
  const Md3eComicDetailPage({
    super.key,
    required this.entry,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries,
    this.onRead,
    this.onReadIncognito,
    this.onMetadataChipTap,
    this.scrollController,
  });

  final Md3eComicDetailEntry entry;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode>? moreMenuEntries;
  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;
  final ValueChanged<String>? onMetadataChipTap;
  final ScrollController? scrollController;

  @override
  State<Md3eComicDetailPage> createState() => _Md3eComicDetailPageState();
}

class _Md3eComicDetailPageState extends State<Md3eComicDetailPage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;
  late Md3eComicDetailEntry _entry = widget.entry;
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didUpdateWidget(covariant Md3eComicDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _entry = widget.entry;
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

  VoidCallback _resolveVoid(VoidCallback? handler) {
    return handler ?? () {};
  }

  List<M3EMenuNode> _resolveMoreMenu(AppLocalizations l10n) {
    if (widget.moreMenuEntries != null) {
      return widget.moreMenuEntries!;
    }
    return <M3EMenuNode>[
      M3EMenuEntry(
        label: l10n.comicDetailShowInExplorer,
        leading: const Icon(Symbols.folder_open),
        onPressed: () {},
      ),
      M3EMenuEntry(
        label: l10n.comicDetailDelete,
        leading: Icon(Symbols.delete, color: M3ETheme.of(context).colorScheme.error),
        onPressed: () {},
      ),
    ];
  }

  void _selectSeriesIndex(int index) {
    if (index < 0 || index >= _entry.seriesCatalog.length) {
      return;
    }
    setState(() {
      _entry = _entry.copyWith(
        title: _entry.seriesCatalog[index],
        seriesCurrentIndex: index,
      );
    });
  }

  void _seriesPrev() {
    _selectSeriesIndex(_entry.seriesCurrentIndex - 1);
  }

  void _seriesNext() {
    _selectSeriesIndex(_entry.seriesCurrentIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double horizontalPadding =
        Md3eComicDetailPageMetrics.contentHorizontalPadding(sizeClass);

    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Md3eComicDetailPageHeader(
          onBack: _resolveVoid(widget.onBack),
          onEdit: _resolveVoid(widget.onEdit),
          moreMenuEntries: _resolveMoreMenu(l10n),
          showSeriesNav: _entry.showSeriesNav,
          seriesCatalog: _entry.seriesCatalog,
          seriesCurrentIndex: _entry.seriesCurrentIndex,
          onSeriesSelectIndex: _selectSeriesIndex,
          onSeriesPrev: _seriesPrev,
          onSeriesNext: _seriesNext,
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
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverToBoxAdapter(
                  child: Md3eComicDetailScrollContent(
                    entry: _entry,
                    onRead: _resolveVoid(widget.onRead),
                    onReadIncognito: _resolveVoid(widget.onReadIncognito),
                    onMetadataChipTap: widget.onMetadataChipTap ?? (_) {},
                  ),
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
