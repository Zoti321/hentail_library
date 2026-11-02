import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_md3e/series_detail_page_entry.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/series_detail/series_detail_comics_section.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/series_detail/series_detail_intro_section.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/series_detail/series_detail_page_header.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

export 'package:hentai_library/features/library_browse/presentation/views/series_detail_md3e/series_detail_page_entry.dart';

/// 系列详情页 Lab：粘滞页头 + 可滚动简介与漫画网格。
///
/// [entry.comics] 仅为当前页；页码、页大小与总页数由调用方通过受控参数提供。
class Md3eSeriesDetailPage extends StatefulWidget {
  const Md3eSeriesDetailPage({
    super.key,
    required this.entry,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.onPageChanged,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries,
    this.onMetadataChipTap,
    this.onComicTap,
    this.onAuthorTap,
    this.scrollController,
    this.onPageSizeChanged,
  });

  final Md3eSeriesDetailEntry entry;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode>? moreMenuEntries;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<int>? onComicTap;

  /// 作者 chip 点击（生产：打开作者详情）；为空时作者 chip 走 [onMetadataChipTap]。
  final ValueChanged<String>? onAuthorTap;
  final ScrollController? scrollController;

  final int page;
  final int pageSize;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;

  @override
  State<Md3eSeriesDetailPage> createState() => _Md3eSeriesDetailPageState();
}

class _Md3eSeriesDetailPageState extends State<Md3eSeriesDetailPage> {
  final GlobalKey _comicsSectionKey = GlobalKey();
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
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
    final int target = page.clamp(1, widget.totalPages);
    widget.onPageChanged(target);
    _scrollToComicsSection();
  }

  void _setPageSize(int size) {
    widget.onPageSizeChanged?.call(size);
    _scrollToComicsSection();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;
    final double introTop = layout.headerToBodyGap;

    final Widget header = Md3eSeriesDetailPageHeader(
      onBack: _resolveVoid(widget.onBack),
      onEdit: _resolveVoid(widget.onEdit),
      moreMenuEntries: _resolveMoreMenu(l10n),
      pageSize: widget.pageSize,
      onPageSizeChanged: _setPageSize,
    );

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(scheme),
      child: Stack(
        children: <Widget>[
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: Md3ePageHeaderDelegate(layout: layout, child: header),
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
                    onAuthorTap: widget.onAuthorTap,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: Md3eSeriesDetailComicsSection(
                  gridSectionKey: _comicsSectionKey,
                  pageItems: widget.entry.comics,
                  page: widget.page,
                  totalPages: widget.totalPages,
                  onPageChanged: _setPage,
                  onComicTap: widget.onComicTap == null
                      ? null
                      : (int localIndex) {
                          final int globalIndex =
                              (widget.page - 1) * widget.pageSize + localIndex;
                          widget.onComicTap!(globalIndex);
                        },
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
