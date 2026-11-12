import 'package:flutter/material.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/catalog/selection/catalog_selection_notifier.dart';
import 'package:hentai_library/shared/ui/catalog/selection/library_selection_header.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/di/series_slot_providers.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_comics_section.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_intro_section.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_page_header.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

export 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';

/// 系列详情页 Lab：粘滞页头 + 可滚动简介与漫画网格。
///
/// [entry.comics] 仅为当前页；页码、页大小与总页数由调用方通过受控参数提供。
class SeriesDetailLayout extends ConsumerStatefulWidget {
  const SeriesDetailLayout({
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

  final SeriesDetailViewObject entry;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode>? moreMenuEntries;
  final ValueChanged<String>? onMetadataChipTap;
  final ValueChanged<int>? onComicTap;

  /// 作者 chip 点击（生产：打开作者详情）；为空时作者 chip 走 [onMetadataChipTap]。
  final ValueChanged<AuthorRef>? onAuthorTap;
  final ScrollController? scrollController;

  final int page;
  final int pageSize;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;

  @override
  ConsumerState<SeriesDetailLayout> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends ConsumerState<SeriesDetailLayout> {
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

  void _handlePopInvoked(bool didPop, bool seriesSelection) {
    if (!didPop && seriesSelection) {
      ref.read(catalogSelectionProvider.notifier).exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;
    final double introTop = layout.headerToBodyGap;

    // 只订阅选择模式布尔，避免勾选 selectedIds 重建简介与整页壳。
    final bool seriesSelection = ref.watch(
      catalogSelectionProvider.select(
        (CatalogSelectionState state) => state.isSeriesDetailSelection,
      ),
    );
    final List<String> pageComicIds = <String>[
      for (final SeriesDetailComicItem item in widget.entry.comics)
        if (item.comic != null) item.comic!.comicId,
    ];

    final Widget modeHeader = seriesSelection
        ? LibrarySelectionHeader(
            pageComicIds: pageComicIds,
            onEditMetadata: ref.watch(seriesMemberSelectionActionsSlotProvider),
          )
        : SeriesDetailPageHeader(
            onBack: _resolveVoid(widget.onBack),
            onEdit: _resolveVoid(widget.onEdit),
            moreMenuEntries: _resolveMoreMenu(l10n),
            pageSize: widget.pageSize,
            onPageSizeChanged: _setPageSize,
          );

    final Widget header = ModeChromeTransition(
      switchKey: seriesSelection,
      reverse: !seriesSelection,
      child: modeHeader,
    );

    return PopScope(
      canPop: !seriesSelection,
      onPopInvokedWithResult: (bool didPop, Object? result) =>
          _handlePopInvoked(didPop, seriesSelection),
      child: ColoredBox(
        color: labBrowseCanvasColor(scheme),
        child: Stack(
          children: <Widget>[
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PageHeaderDelegate(layout: layout, child: header),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    introTop,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: SeriesDetailIntroSection(
                      entry: widget.entry,
                      onMetadataChipTap: widget.onMetadataChipTap ?? (_) {},
                      onAuthorTap: widget.onAuthorTap,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SeriesDetailComicsSection(
                    gridSectionKey: _comicsSectionKey,
                    pageItems: widget.entry.comics,
                    page: widget.page,
                    totalPages: widget.totalPages,
                    onPageChanged: _setPage,
                    onComicTap: widget.onComicTap == null
                        ? null
                        : (int localIndex) {
                            final int globalIndex =
                                (widget.page - 1) * widget.pageSize +
                                localIndex;
                            widget.onComicTap!(globalIndex);
                          },
                  ),
                ),
              ],
            ),
            ExpressiveLibraryScrollToTopButton(
              scrollController: _scrollController,
              horizontalPadding: horizontalPadding,
            ),
          ],
        ),
      ),
    );
  }
}
